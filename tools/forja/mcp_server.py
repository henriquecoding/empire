"""Servidor MCP (stdio, JSON-RPC 2.0) com as ferramentas da Forja.

Sem dependencias: le uma mensagem JSON por linha no stdin e responde no stdout.
As ferramentas sao os subcomandos da CLI (forja_forge, forja_sheet, ...), com
os esquemas derivados do argparse — o agente e o terminal veem a mesma coisa.
As respostas trazem o JSON do resultado e, quando ha, a previa ampliada como
imagem, para o agente VER o que fez antes de seguir.

Ligar: Codex (~/.codex/config.toml), Claude Code (.mcp.json) e outros clientes
com `python3 -m tools.forja mcp`, a partir da raiz do repositorio. Ver docs/art/FORJA.md.
"""
from __future__ import annotations

import argparse
import base64
import contextlib
import io
import json
import os
import sys
from pathlib import Path

from PIL import Image

from . import __version__, cli
from .imageops import open_rgba

VERSIONS = ("2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05")
SKIP = {"mcp"}
INSTRUCTIONS = (
    "Forja: pixel art verdadeira para o jogo Empire a partir de imagens geradas. Fluxo: (1) forja_prompt compila "
    "o pedido (prompt, tamanho, guias, expect.json); (2) gere a imagem com a tua ferramenta (ou forja_generate "
    "com chave); (3) forja_forge (uma figura) ou forja_sheet (prancha) com --expect; (4) le os achados e o "
    "prompt_feedback; se nao passou, gera de novo com o prompt corrigido. Caminhos relativos a raiz do repositorio. "
    "Nunca escrever em art/ sem pedido do dono; usar build/forja/. Ler docs/art/FORJA.md.")


def _schema(parser: argparse.ArgumentParser) -> dict:
    props, required = {}, []
    for action in parser._actions:
        if isinstance(action, argparse._HelpAction) or action.dest in ("handler", "command"):
            continue
        name = action.dest
        if isinstance(action, argparse._StoreTrueAction):
            prop = {"type": "boolean"}
        elif action.nargs in ("+", "*"):
            prop = {"type": "array", "items": {"type": "string"}}
        elif action.type is int:
            prop = {"type": "integer"}
        elif action.type is float:
            prop = {"type": "number"}
        else:
            prop = {"type": "string"}
        if action.choices:
            prop["enum"] = list(action.choices)
        if action.type is cli.pair:
            prop["description"] = "LxA, ex.: 64x64"
        if action.type is cli.box:
            prop["description"] = "x0,y0,x1,y1"
        if action.help:
            prop["description"] = (prop.get("description", "") + " " + action.help).strip()
        if action.default not in (None, False, argparse.SUPPRESS):
            prop["default"] = action.default
        props[name] = prop
        if not action.option_strings or action.required:
            required.append(name)
    return {"type": "object", "properties": props, "required": required}


def tools() -> list[dict]:
    cli.build_parser()
    return [{"name": f"forja_{name}", "description": parser.description, "inputSchema": _schema(parser)}
            for name, (parser, _) in cli.REGISTRY.items() if name not in SKIP]


def _argv(name: str, arguments: dict) -> list[str]:
    parser, _ = cli.REGISTRY[name]
    argv = [name]
    for action in parser._actions:
        if action.dest not in arguments or arguments[action.dest] is None:
            continue
        value = arguments[action.dest]
        if not action.option_strings:
            argv += [str(v) for v in value] if isinstance(value, list) else [str(value)]
        elif isinstance(action, argparse._StoreTrueAction):
            argv += [action.option_strings[-1]] if value else []
        elif isinstance(value, list):
            argv += [action.option_strings[-1]] + [str(v) for v in value]
        else:
            argv += [action.option_strings[-1], str(value)]
    return argv


def _preview(result: dict) -> dict | None:
    files = result.get("files") or {}
    for key in ("preview", "sheet", "demo", "layout"):
        path = files.get(key)
        if path and str(path).endswith(".png") and Path(path).exists():
            break
    else:
        path = result.get("out") if str(result.get("out", "")).endswith(".png") else None
    if not path or not Path(path).exists():
        return None
    img = open_rgba(path)
    factor = max(1, min(8, 768 // max(img.size)))
    if factor > 1:
        img = img.resize((img.width * factor, img.height * factor), Image.Resampling.NEAREST)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    if buf.tell() > 3_000_000:
        return None
    return {"type": "image", "data": base64.b64encode(buf.getvalue()).decode("ascii"), "mimeType": "image/png"}


def call(name: str, arguments: dict) -> dict:
    command = name[len("forja_"):] if name.startswith("forja_") else name
    if command not in cli.REGISTRY or command in SKIP:
        return {"content": [{"type": "text", "text": f"ferramenta desconhecida: {name}"}], "isError": True}
    errors = io.StringIO()
    try:
        with contextlib.redirect_stdout(sys.stderr), contextlib.redirect_stderr(errors):
            result = cli.run(_argv(command, arguments or {}))
    except SystemExit:
        return {"content": [{"type": "text", "text": "argumentos invalidos: " + errors.getvalue()}], "isError": True}
    except Exception as err:  # noqa: BLE001 — o erro volta ao agente, o servidor continua
        return {"content": [{"type": "text", "text": f"{type(err).__name__}: {err}"}], "isError": True}
    content = [{"type": "text", "text": json.dumps(result, ensure_ascii=False, indent=1)}]
    image = _preview(result)
    if image:
        content.append(image)
    return {"content": content, "isError": False}


def handle(message: dict) -> dict | None:
    method, mid = message.get("method"), message.get("id")
    if mid is None:
        return None
    if method == "initialize":
        asked = (message.get("params") or {}).get("protocolVersion")
        result = {"protocolVersion": asked if asked in VERSIONS else VERSIONS[0],
                  "capabilities": {"tools": {"listChanged": False}},
                  "serverInfo": {"name": "forja", "version": __version__}, "instructions": INSTRUCTIONS}
    elif method == "ping":
        result = {}
    elif method == "tools/list":
        result = {"tools": tools()}
    elif method == "tools/call":
        params = message.get("params") or {}
        result = call(params.get("name", ""), params.get("arguments") or {})
    else:
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"metodo desconhecido: {method}"}}
    return {"jsonrpc": "2.0", "id": mid, "result": result}


def serve(stdin=None, stdout=None) -> None:
    """Corre a partir da raiz do repositorio, seja qual for a pasta do cliente."""
    os.chdir(Path(__file__).resolve().parents[2])
    stdin = stdin or sys.stdin
    stdout = stdout or sys.stdout
    for line in stdin:
        line = line.strip()
        if not line:
            continue
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "JSON invalido"}}
        else:
            reply = handle(message)
        if reply is not None:
            stdout.write(json.dumps(reply, ensure_ascii=False) + "\n")
            stdout.flush()
