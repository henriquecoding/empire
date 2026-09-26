#!/usr/bin/env python3
"""tools/manifesto.py — com que motor e com que ecra uma imagem foi tirada.

Uma captura so se compara com outra se as duas disserem o mesmo sobre cinco
coisas: o commit, o motor, o renderer, a resolucao e a escala. Ate 26/09 o
`.godot-version` e a publicacao usavam 4.6 e o `project.godot` declarava 4.7 —
o que o editor escreve quando abre o projeto noutra versao. Nada rebentou por
causa disso; o que se perdeu foi a certeza de que duas imagens vinham do mesmo
sitio.

Este e o manifesto do que se DECLARA. O que CORREU mesmo — o renderer depois
da queda de Vulkan para OpenGL num ecra virtual, o adaptador, a semente — so o
motor sabe, e vai na ficha de cada captura (tools/captura.gd).

    python3 tools/manifesto.py            # o manifesto, em JSON
    python3 tools/manifesto.py --check    # chumba se o motor declarado diverge

O `--check` e o portao: um `config/features` com outra versao que nao a do
`.godot-version` quer dizer que alguem abriu o projeto noutro editor. Ou volta
a versao fixada, ou sobe-se o `.godot-version` — e isso e uma decisao, com ADR.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

# O que o motor usa quando o project.godot nao diz nada. Sao os valores por
# omissao do Godot 4.6, e estao aqui para que o manifesto diga o que CORRE e
# nao so o que esta escrito.
OMISSAO = {
    "display/window/stretch/mode": "disabled",
    "display/window/stretch/aspect": "keep",
    "display/window/stretch/scale_mode": "fractional",
    "rendering/textures/canvas_textures/default_texture_filter": "1",
    "rendering/renderer/rendering_method": "forward_plus",
    "rendering/renderer/rendering_method.web": "gl_compatibility",
}
FILTROS = {"0": "nearest", "1": "linear", "2": "nearest_mipmap", "3": "linear_mipmap"}


def ler_projeto(texto: str) -> dict[str, str]:
    """As chaves do project.godot como `seccao/chave`, com o valor em texto."""
    saida: dict[str, str] = {}
    seccao = ""
    for linha in texto.splitlines():
        linha = linha.strip()
        if not linha or linha.startswith(";"):
            continue
        cabeca = re.fullmatch(r"\[(.+)\]", linha)
        if cabeca:
            seccao = cabeca.group(1)
            continue
        chave, igual, valor = linha.partition("=")
        if igual and re.fullmatch(r"[\w./]+", chave):
            saida[f"{seccao}/{chave}"] = valor.strip().strip('"')
    return saida


def valor(projeto: dict[str, str], chave: str) -> str:
    return projeto.get(chave, OMISSAO.get(chave, ""))


def versao_declarada(projeto: dict[str, str]) -> str:
    """A versao que o editor escreveu em `config/features`, ou vazio."""
    features = projeto.get("application/config/features", "")
    achado = re.search(r'"(\d+\.\d+)"', features)
    return achado.group(1) if achado else ""


def git(*args: str) -> str:
    r = subprocess.run(["git", *args], cwd=RAIZ, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def manifesto() -> dict:
    projeto = ler_projeto((RAIZ / "project.godot").read_text(encoding="utf-8"))
    fixada = (RAIZ / ".godot-version").read_text(encoding="utf-8").strip()
    return {
        "commit": git("rev-parse", "HEAD"),
        "sujo": bool(git("status", "--porcelain", "--untracked-files=no")),
        "motor_fixado": fixada,
        "motor_declarado": versao_declarada(projeto),
        "renderer": {
            "desktop": valor(projeto, "rendering/renderer/rendering_method"),
            "web": valor(projeto, "rendering/renderer/rendering_method.web"),
        },
        "base": [
            int(valor(projeto, "display/window/size/viewport_width") or 0),
            int(valor(projeto, "display/window/size/viewport_height") or 0),
        ],
        "esticar": valor(projeto, "display/window/stretch/mode"),
        "aspecto": valor(projeto, "display/window/stretch/aspect"),
        "escala": valor(projeto, "display/window/stretch/scale_mode"),
        "filtro": FILTROS.get(
            valor(projeto, "rendering/textures/canvas_textures/default_texture_filter"), "?"
        ),
        "tick_hz": int(valor(projeto, "physics/common/physics_ticks_per_second") or 60),
    }


def conferir(m: dict) -> list[str]:
    erros = []
    fixada = re.match(r"(\d+\.\d+)", m["motor_fixado"])
    if fixada is None:
        erros.append(f".godot-version ilegivel: {m['motor_fixado']!r}")
    elif m["motor_declarado"] != fixada.group(1):
        erros.append(
            f"project.godot declara {m['motor_declarado'] or 'nada'} em config/features e o "
            f".godot-version fixa {m['motor_fixado']}: repoe a versao fixada, ou sobe o "
            ".godot-version com uma ADR"
        )
    return erros


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="chumba se o motor diverge")
    args = parser.parse_args()
    m = manifesto()
    if not args.check:
        print(json.dumps(m, indent=2, ensure_ascii=False))
        return 0
    erros = conferir(m)
    for e in erros:
        print(f"manifesto: {e}", file=sys.stderr)
    if not erros:
        print(
            f"manifesto: motor {m['motor_fixado']} · renderer {m['renderer']['desktop']}"
            f" (web {m['renderer']['web']}) · {m['esticar']}/{m['escala']} · filtro {m['filtro']}"
        )
    return 1 if erros else 0


if __name__ == "__main__":
    raise SystemExit(main())
