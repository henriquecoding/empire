#!/usr/bin/env python3
"""tools/inventario_arte.py — que arte original o jogo usa, onde, e o que lhe falta.

O ASSET_REGISTER.csv e o plano de arte: 261 pecas com o estado de cada uma, e
duas marcadas IN_GAME. Isso nao quer dizer que so duas aparecam no jogo — o
castelo-arvore, a tropa, o rei e o cozinheiro ja la estao, pelo manifesto de
art/export/enramados/. O planejamento de 26/09 (§4.5) pede que se registe em
separado fonte, export, chamada em runtime, accoes disponiveis e aprovacao, e
que nada passe a "concluido" por existir uma textura. E isso que isto faz, lido
do repositorio — o manifesto, os CSV, e o que liga dados a arte
(OriginalArt.unit_profile, as tabelas do BuildingSkins e do PaintedArt, os povos
do NativeSprites e as texturas do cenario) — e escrito em docs/art/RUNTIME_ART.md.

    python3 tools/inventario_arte.py            # reescreve docs/art/RUNTIME_ART.md
    python3 tools/inventario_arte.py --check    # chumba se o ficheiro nao estiver em dia

Nao mexe em art/ (AGENTS.md, regra 9) nem no ASSET_REGISTER: le-os.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path
from temporary_art_register import temporary_assets, temporary_table
from renewal_art_register import renewal_assets, renewal_table

RAIZ = Path(__file__).resolve().parent.parent
MANIFESTO = RAIZ / "art/export/enramados/manifest.json"
SAIDA = RAIZ / "docs/art/RUNTIME_ART.md"
GERADO = "<!-- gerado por tools/inventario_arte.py — nao editar a mao -->"


def ler(caminho: str) -> str:
    return (RAIZ / caminho).read_text(encoding="utf-8")


def tabela(caminho: str) -> list[dict[str, str]]:
    with (RAIZ / caminho).open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def corpo(fonte: str, cabeca: str) -> str:
    """O corpo de uma funcao GDScript, da assinatura ate a funcao seguinte."""
    inicio = fonte.index(cabeca)
    fim = re.search(r"\n(static )?func ", fonte[inicio + len(cabeca):])
    return fonte[inicio: inicio + len(cabeca) + fim.start()] if fim else fonte[inicio:]


def ramos(fonte: str, cabeca: str, constantes: dict[str, str]) -> dict[str, str]:
    """Os ramos de um `match` que devolve um StringName: {id de dados: perfil}."""
    saida: dict[str, str] = {}
    texto = corpo(fonte, cabeca)
    for casos, perfil in re.findall(r"\n\t\t([^\n]+):\n(?:\t\t\t#[^\n]*\n)*\t\t\treturn &\"(\w+)\"", texto):
        for caso in casos.split(","):
            caso = caso.strip()
            chave = constantes.get(caso, caso.removeprefix('&"').removesuffix('"'))
            saida[chave] = perfil
    return saida


def pares(fonte: str, const: str, chave: str = r'&"(\w+)"') -> dict[str, str]:
    """Uma constante `const NOME := {chave: &"valor", ...}` de um script, como dicionario."""
    bloco = re.search(rf"const {const} := \{{(.*?)\n\}}", fonte, re.S).group(1)
    return dict(re.findall(rf'{chave}: &"(\w+)"', bloco))


def mapas() -> dict:
    nucleo = re.search(r'const NUCLEO := &"(\w+)"', ler("src/sim/state/build_slot.gd")).group(1)
    # O subsolo e a boca das passagens (AUD-04) montam-se no Cavities, e a escora
    # e a do Passages.
    greybox = ler("src/world/greybox.gd") + ler("src/world/cavities.gd")
    no_marco = set(re.findall(r'const [A-Z_]+ := &"(\w+)"', greybox)) | {nucleo}
    no_marco |= set(re.findall(r'const ESCORA := &"(\w+)"', ler("src/sim/systems/passages.gd")))
    no_marco |= set(re.findall(r'const CASA := &"(\w+)"', ler("src/sim/systems/succession.gd")))
    no_marco |= set(re.findall(r'_por_recrutar\(&"(\w+)"', greybox))
    no_marco |= set(re.findall(r'Registry\.entry\(&"units", &"(\w+)"\)', greybox))
    # Quem se forma numa obra do marco: a obra diz o oficio (`craft`) e a tropa
    # diz onde se forma (`trained_at`) — a mesma regra do SimFactory.training().
    formados = {u["id"]: u["trained_at"] for u in tabela("data/source/units.csv")}
    for b in tabela("data/source/buildings.csv"):
        if b["id"] in no_marco and formados.get(b.get("craft", "")) == b["id"]:
            no_marco.add(b["craft"])
    cenario: dict[str, list[str]] = {}
    for f in sorted((RAIZ / "src").rglob("*.gd")):
        for asset in re.findall(r'\.texture\(&"(\w+)"\)', f.read_text(encoding="utf-8")):
            cenario.setdefault(asset, []).append(f.relative_to(RAIZ).as_posix())
    acao = ler("src/actors/actor_action.gd")
    skins = ler("src/world/building_skins.gd")
    silhueta = ler("src/world/silhouette.gd")
    nativas = ler("src/world/sprites_native.gd")
    return {
        "unidades": {**ramos(ler("src/actors/original_art.gd"), "static func unit_profile", {}),
                      **pares(ler("src/world/renewal_art.gd"), "UNITS")},
        "obras": {**pares(skins, "ORIGINAIS"),
                  **pares(ler("src/world/renewal_art.gd"), "BUILDINGS"), nucleo: "royal_tree_castle"},
        "pintadas": pares(ler("src/world/painted_art.gd"), "OBRAS"),
        "por_forma": pares(skins, "POR_FORMA", r"Silhouette\.Form\.(\w+)"),
        "categorias": pares(silhueta, "POR_CATEGORIA").keys(),
        "forma": {c: f for c, f in re.findall(r'&"(\w+)": Form\.(\w+)', silhueta)},
        "fogo": re.findall(r'const FOGUEIRA := &"(\w+)"', ler("src/world/hearth_art.gd"))
        + re.findall(r'const FAROL := &"(\w+)"', ler("src/core/lume.gd")),
        "povos": re.findall(r'&"(\w+)": Color', ler("src/world/sprites_native.gd")),
        "tipos": re.findall(r'&"(\w+)"', re.search(r"const TIPOS := (\[.*?\])", nativas).group(1)),
        "cenario": cenario,
        "accoes": re.findall(r'Kind\.\w+: &"(\w+)"', acao),
        "no_marco": no_marco,
    }


def celula(itens: list[str] | set[str]) -> str:
    return ", ".join(f"`{x}`" for x in sorted(itens)) or "—"


def exportacoes(manifesto: dict, m: dict) -> tuple[list[str], dict[str, list[str]]]:
    usos: dict[str, list[str]] = {}
    for dados, perfil in m["unidades"].items():
        usos.setdefault(perfil, []).append(f"unidade {dados}")
    for obra, perfil in m["obras"].items():
        usos.setdefault(perfil, []).append(f"obra {obra}")
    chamadas = {
        **{p: "src/actors/unit_art_batch.gd" for p in m["unidades"].values()},
        **{p: "src/world/building_skins.gd" for p in m["obras"].values()},
    }
    linhas = [
        "| Export | Fonte | Frames | Tags (accoes) | Chamada em runtime | Quem a usa | Aprovacao |",
        "|---|---|---:|---|---|---|---|",
    ]
    for asset, item in sorted(manifesto["assets"].items()):
        fonte = f"art/source/originals/{item['source']}.aseprite"
        existe = "" if (RAIZ / fonte).exists() else " (falta)"
        chamada = sorted({chamadas[asset]} if asset in chamadas else set(m["cenario"].get(asset, [])))
        linhas.append(
            f"| `{item['texture']}` | `{fonte}`{existe} | {len(item['durations_ms'])} "
            f"| {celula(item.get('tags', {}))} | {celula(chamada)} "
            f"| {', '.join(sorted(usos.get(asset, []))) or '—'} | `{item['review_status']}` |"
        )
    return linhas, usos


def unidades(manifesto: dict, m: dict) -> tuple[list[str], list[str]]:
    linhas = [
        "| Unidade | Fase | No marco | Arte | Accoes desenhadas | Accoes em falta |",
        "|---|---:|---|---|---|---|",
    ]
    faltas = []
    for u in tabela("data/source/units.csv"):
        perfil = m["unidades"].get(u["id"], "")
        marco = "sim" if u["id"] in m["no_marco"] else ""
        if not perfil:
            arte, tem = "procedural (`ActorArt`)", []
        else:
            tem = sorted(manifesto["assets"][perfil].get("tags", {}))
            arte = f"`{perfil}`" if perfil == u["id"] else f"`{perfil}` — emprestado"
        falta = [a for a in m["accoes"] if a not in tem]
        linhas.append(
            f"| `{u['id']}` | {u['_phase']} | {marco} | {arte} | {celula(tem)} | {celula(falta)} |"
        )
        if marco:
            faltas.append(f"`{u['id']}`: {arte}; faltam {celula(falta)}")
    return linhas, faltas


def obras(manifesto: dict, m: dict) -> tuple[list[str], list[str]]:
    linhas = ["| Obra | Fase | No marco | Arte | Estados |", "|---|---:|---|---|---|"]
    faltas = []
    for b in tabela("data/source/buildings.csv"):
        marco = "sim" if b["id"] in m["no_marco"] else ""
        perfil = m["obras"].get(b["id"], "")
        pintada = m["pintadas"].get(b["id"], "")
        povo, _, tipo = b["id"].rpartition("_")
        forma = "MASTRO" if "anti_air" in b["tags"].split("|") else m["forma"].get(b["category"], "")
        pela_forma = m["por_forma"].get(forma, "")
        if b["id"] in m["fogo"]:
            arte, estados = "procedural (`HearthArt`)", "por codigo"
        elif perfil:
            partilhada = [o for o, p in m["obras"].items() if p == perfil and o != b["id"]]
            arte = f"`{perfil}`" + (f" — partilhada com {celula(partilhada)}" if partilhada else "")
            estados = f"{len(manifesto['assets'][perfil]['durations_ms'])} frame; estados por codigo"
        elif pintada:
            partilhada = [o for o, p in m["pintadas"].items() if p == pintada and o != b["id"]]
            arte = f"pintada (`PaintedArt`): `{pintada}`" + (
                f" — partilhada com {celula(partilhada)}" if partilhada else ""
            )
            estados = "1 imagem; estados por codigo"
        elif povo in m["povos"] and tipo in m["tipos"]:
            arte, estados = f"pintada (`NativeSprites`): `native_{b['id']}`", "1 imagem; estados por codigo"
        elif pela_forma:
            origem = "" if pela_forma in manifesto["assets"] else "pintada, "
            arte, estados = f"{origem}pela forma `{forma}`: `{pela_forma}`", "1 imagem; estados por codigo"
        else:
            arte, estados = "procedural (`Silhouette`/`StructureArt`)", "por codigo"
        linhas.append(f"| `{b['id']}` | {b['_phase']} | {marco} | {arte} | {estados} |")
        if marco:
            faltas.append(f"`{b['id']}`: {arte}; {estados}")
    return linhas, faltas


def documento() -> str:
    manifesto = json.loads(MANIFESTO.read_text(encoding="utf-8"))
    m = mapas()
    tab_export, usos = exportacoes(manifesto, m)
    ativos = {"assets": {**manifesto["assets"], **temporary_assets(), **renewal_assets()}}
    tab_unid, faltas_unid = unidades(ativos, m)
    tab_obras, faltas_obras = obras(ativos, m)
    niveis = len(tabela("data/source/walls.csv"))
    faltas_obras.append(
        f"muralha (`walls.csv`, {niveis} niveis): pintada (`WallSprites`): "
        f"{celula([f'wall_{n}' for n in range(1, niveis + 1)])}; 1 imagem por nivel, estados por codigo"
    )
    sem_uso = [a for a in manifesto["assets"] if a not in usos and a not in m["cenario"]]
    estados = sorted({i["review_status"] for i in manifesto["assets"].values()})
    em_jogo = sum(1 for r in tabela("docs/art/ASSET_REGISTER.csv") if r["status"] == "IN_GAME")
    partes = [
        "# Arte em runtime — o que o jogo desenha com os originais",
        "",
        GERADO,
        "",
        "Lido do manifesto de `art/export/enramados/`, dos CSV e das funcoes que ligam dados a arte. "
        "Fonte, export, chamada em runtime, accoes e aprovacao sao colunas separadas: existir uma "
        "textura nao conclui nada. O `ASSET_REGISTER.csv` continua a ser o plano de producao e nao "
        f"e alterado por isto (tem {em_jogo} linhas `IN_GAME`, que nao contam estas exportacoes).",
        "",
        f"Accoes do contrato (`src/actors/actor_action.gd`): {celula(m['accoes'])}. "
        "Uma accao sem tag no manifesto mostra o repouso (fugir mostra a caminhada, se existir).",
        "",
        "## Exportacoes dos originais",
        "",
        *tab_export,
        "",
        "## Unidades",
        "",
        *tab_unid,
        "",
        "## Obras",
        "",
        *tab_obras,
        "",
        "## Lacunas de arte do marco dos Enramados",
        "",
        "O que o marco usa e ainda nao tem arte propria, accoes desenhadas ou aprovacao. "
        "\"No marco\" e o que o `Greybox` monta e quem se forma nas obras que ele monta.",
        "",
        "**Unidades**",
        "",
        *[f"- {x}" for x in faltas_unid],
        "",
        "**Obras**",
        "",
        *[f"- {x}" for x in faltas_obras],
        "",
        "**Exportacoes**",
        "",
        f"- Sem chamada em runtime: {celula(sem_uso)}.",
        f"- Estados de aprovacao presentes: {celula(estados)}. Nenhuma exportacao esta aprovada.",
        "",
    ]
    return "\n".join(partes + temporary_table() + renewal_table())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="chumba se nao estiver em dia")
    args = parser.parse_args()
    texto = documento()
    if args.check:
        atual = SAIDA.read_text(encoding="utf-8") if SAIDA.exists() else ""
        if atual != texto:
            print("inventario-arte: docs/art/RUNTIME_ART.md nao esta em dia — corre "
                  "python3 tools/inventario_arte.py", file=sys.stderr)
            return 1
        print("inventario-arte: docs/art/RUNTIME_ART.md em dia")
        return 0
    SAIDA.write_text(texto, encoding="utf-8")
    print(f"inventario-arte: {SAIDA.relative_to(RAIZ)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
