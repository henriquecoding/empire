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
from .mcp_instructions import INSTRUCTIONS

VERSIONS = ("2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05")
SKIP = {"mcp"}
READ_ONLY = {"kinds", "lint", "verify", "regua", "ase"}
PAID = {"generate", "auto", "inpaint", "animar"}


def _schema(parser: argparse.ArgumentParser) -> dict:
    props, required = {}, []
    for action in parser._actions:
        if isinstance(action, argparse._HelpAction) or action.dest in ("handler", "command"):
            continue
        name = action.dest
        if isinstance(action, argparse._StoreTrueAction):
            prop = {"type": "boolean"}
        elif action.nargs in ("+", "*") or isinstance(action, argparse._AppendAction):
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


def annotations(name: str) -> dict:
    """O que o cliente sabe antes de chamar (MCP 2025-03-26+): o pago sai para a rede e nao se repete igual; os jobs
    consultam e cancelam no fornecedor; o resto so escreve as suas saidas."""
    if name in READ_ONLY:
        return {"readOnlyHint": True, "openWorldHint": False}
    if name in PAID:
        return {"readOnlyHint": False, "destructiveHint": False, "idempotentHint": False, "openWorldHint": True}
    if name == "jobs":
        return {"readOnlyHint": False, "destructiveHint": True, "idempotentHint": False, "openWorldHint": True}
    return {"readOnlyHint": False, "destructiveHint": False, "idempotentHint": name != "refs", "openWorldHint": False}


def tools() -> list[dict]:
    _registry()
    return [{"name": f"forja_{name}", "title": f"Forja {name}", "description": parser.description,
             "inputSchema": _schema(parser), "annotations": annotations(name)}
            for name, (parser, _) in cli.REGISTRY.items() if name not in SKIP]


def _registry() -> dict:
    return cli.REGISTRY or (cli.build_parser() and cli.REGISTRY)  # `forja mcp` ja o montou; quem importa, nao


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
        elif isinstance(action, argparse._AppendAction):  # repetivel: uma flag por item (A06)
            for item in value if isinstance(value, list) else [value]:
                argv += [action.option_strings[-1], str(item)]
        elif isinstance(value, list):
            argv += [action.option_strings[-1]] + [str(v) for v in value]
        else:
            argv += [action.option_strings[-1], str(value)]
    return argv


def _preview(result: dict) -> dict | None:
    files = result.get("files") or {}
    for key in ("preview", "sheet", "demo", "layout", "day", "bench", "ruler"):
        path = files.get(key)
        if path and str(path).endswith(".png") and Path(path).exists():
            break
    else:
        path = result.get("out") if str(result.get("out", "")).endswith(".png") else None
    if not path or not Path(path).exists():
        return None
    img = open_rgba(path)
    factor = max(1, min(8, 768 // max(img.size)))
    img = img.resize((img.width * factor, img.height * factor), Image.Resampling.NEAREST) if factor > 1 else img
    buf = io.BytesIO()
    img.save(buf, "PNG")
    data = base64.b64encode(buf.getvalue()).decode("ascii")
    return None if buf.tell() > 3_000_000 else {"type": "image", "data": data, "mimeType": "image/png"}


class UnknownTool(KeyError):
    """Erro de protocolo (-32602), nao de execucao: o nome nao e de nenhuma ferramenta (MCP, Tools, Error Handling)."""


def call(name: str, arguments: dict) -> dict:
    command = name[len("forja_"):] if name.startswith("forja_") else name
    if command not in _registry() or command in SKIP:
        raise UnknownTool(name)
    errors = io.StringIO()
    try:
        with contextlib.redirect_stdout(sys.stderr), contextlib.redirect_stderr(errors):
            result = cli.run(_argv(command, arguments or {}))
    except SystemExit:
        return {"content": [{"type": "text", "text": "argumentos invalidos: " + errors.getvalue()}], "isError": True}
    except Exception as err:  # noqa: BLE001 — o erro volta ao agente, o servidor continua
        return {"content": [{"type": "text", "text": f"{type(err).__name__}: {err}"}], "isError": True}
    content = [{"type": "text", "text": json.dumps(result, ensure_ascii=False, indent=1)}]
    content += [image] if (image := _preview(result)) else []
    # sem `structuredContent`: ha clientes que, com ele, so passam esse campo ao modelo, e a previa perdia-se (B12)
    return {"content": content, "isError": False}


def _error(mid, code: int, message: str) -> dict:
    return {"jsonrpc": "2.0", "id": mid, "error": {"code": code, "message": message}}


def handle(message) -> dict | None:
    """Uma mensagem JSON-RPC; o que nao e pedido valido e erro com id null (JSON-RPC 2.0, §5) e o batch, que o MCP
    tirou em 2025-06-18, e recusado. Antes, `[]` ou `42` acabavam com o servidor (FORJA-08, B04)."""
    if isinstance(message, list):
        return _error(None, -32600, "batch JSON-RPC nao suportado: uma mensagem por linha (MCP 2025-06-18)")
    if not isinstance(message, dict):
        return _error(None, -32600, "pedido invalido: um objeto JSON-RPC 2.0")
    method, mid = message.get("method"), message.get("id")
    if not isinstance(method, str):  # uma resposta do cliente, ou lixo com id
        return None if mid is None or "result" in message or "error" in message else _error(
            mid, -32600, "pedido invalido: falta o metodo")
    params = message.get("params") or {}
    if mid is None:
        return None
    if not isinstance(params, dict):
        return _error(mid, -32602, "params tem de ser um objeto")
    if method == "initialize":
        asked = params.get("protocolVersion")
        result = {"protocolVersion": asked if asked in VERSIONS else VERSIONS[0],
                  "capabilities": {"tools": {"listChanged": False}},
                  "serverInfo": {"name": "forja", "title": "Forja (Empire)", "version": __version__},
                  "instructions": INSTRUCTIONS}
    elif method == "ping":
        result = {}
    elif method == "tools/list":
        result = {"tools": tools()}
    elif method == "tools/call":
        arguments = params.get("arguments") or {}
        if not isinstance(arguments, dict):
            return _error(mid, -32602, "arguments tem de ser um objeto")
        try:
            result = call(str(params.get("name", "")), arguments)
        except UnknownTool as err:
            return _error(mid, -32602, f"ferramenta desconhecida: {err.args[0]}")
    else:
        return _error(mid, -32601, f"metodo desconhecido: {method}")
    return {"jsonrpc": "2.0", "id": mid, "result": result}


def _reply(line) -> dict | None:
    try:
        text = line.decode("utf-8") if isinstance(line, bytes) else line
    except UnicodeDecodeError:
        return _error(None, -32700, "mensagem que nao e UTF-8")
    if not text.strip():
        return None
    try:
        message = json.loads(text)
    except json.JSONDecodeError:
        return _error(None, -32700, "JSON invalido")
    try:
        return handle(message)
    except Exception as err:  # noqa: BLE001 — o servidor continua; o erro vai ao cliente
        return _error(message.get("id") if isinstance(message, dict) else None, -32603,
                      f"erro interno: {type(err).__name__}: {err}")


def serve(stdin=None, stdout=None) -> None:
    """Corre a partir da raiz do repositorio, seja qual for a pasta do cliente.

    As mensagens sao UTF-8 (MCP, Transports): o stdin le-se em bytes e o stdout escreve UTF-8, com \\n, seja qual
    for a codificacao da consola. No Windows um pipe vinha em cp1252: "cenários" chegava "cenÃ¡rios", e um caractere
    fora do cp1252 na resposta rebentava o servidor (FORJA-08, B10)."""
    os.chdir(Path(__file__).resolve().parents[2])
    if stdout is None and hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
        sys.stderr.reconfigure(encoding="utf-8", errors="backslashreplace")
    stdout = stdout or sys.stdout
    for line in stdin if stdin is not None else sys.stdin.buffer:
        reply = _reply(line)
        if reply is not None:
            stdout.write(json.dumps(reply, ensure_ascii=False) + "\n")
            stdout.flush()
