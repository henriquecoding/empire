#!/usr/bin/env python3
"""Parte o dossie HTML em docs/design/NN-slug.md, um ficheiro por seccao.

Uso:  python3 tools/split_dossie.py docs/dossie.html docs/design
So usa a biblioteca padrao. Idempotente: reescreve a pasta de destino.
"""
import html
import os
import re
import sys
import unicodedata

TAGS_FORA = ("script", "style", "svg", "figure", "nav", "footer")


def slug(txt: str) -> str:
    txt = unicodedata.normalize("NFKD", txt).encode("ascii", "ignore").decode()
    txt = re.sub(r"[^a-zA-Z0-9]+", "-", txt).strip("-").lower()
    return re.sub(r"-{2,}", "-", txt)[:48]


def texto(frag: str) -> str:
    frag = re.sub(r"<br\s*/?>", "\n", frag)
    frag = re.sub(r"<[^>]+>", "", frag)
    return html.unescape(frag).strip()


def linha_tabela(celulas) -> str:
    return "| " + " | ".join(c.replace("|", "\\|") for c in celulas) + " |"


def tabela_md(frag: str) -> str:
    linhas, cabecalho = [], None
    for tr in re.findall(r"<tr\b.*?</tr>", frag, re.S):
        celulas = [
            " ".join(texto(c).split())
            for c in re.findall(r"<t[hd]\b.*?</t[hd]>", tr, re.S)
        ]
        if not celulas:
            continue
        if cabecalho is None and "<th" in tr:
            cabecalho = celulas
            linhas.append(linha_tabela(celulas))
            linhas.append(linha_tabela(["---"] * len(celulas)))
        else:
            if cabecalho and len(celulas) < len(cabecalho):
                celulas += [""] * (len(cabecalho) - len(celulas))
            linhas.append(linha_tabela(celulas))
    return "\n".join(linhas) + "\n"


def bloco(frag: str) -> str:
    """Converte um pedaco de HTML do dossie em Markdown."""
    saida = []
    padrao = re.compile(
        r"<(h4|h5|p|ul|ol|pre|table|dl)\b[^>]*>.*?</\1>"
        r"|<div class=\"(note|kv|grid|steps)[^\"]*\".*?</div>\s*(?=<|$)",
        re.S,
    )
    for m in padrao.finditer(frag):
        bruto = m.group(0)
        tag = m.group(1) or m.group(2)
        if tag == "h4":
            saida.append("## " + texto(bruto))
        elif tag == "h5":
            saida.append("### " + texto(bruto))
        elif tag == "pre":
            corpo = re.sub(r"</?(code|span)[^>]*>", "", bruto)
            corpo = html.unescape(re.sub(r"</?pre[^>]*>", "", corpo)).strip("\n")
            saida.append("```gdscript\n" + corpo + "\n```")
        elif tag == "table":
            saida.append(tabela_md(bruto))
        elif tag in ("ul", "ol"):
            itens = re.findall(r"<li\b.*?</li>", bruto, re.S)
            marca = "- " if tag == "ul" else "1. "
            saida.append("\n".join(marca + " ".join(texto(i).split()) for i in itens))
        elif tag in ("kv", "dl"):
            pares = re.findall(r"<dt\b.*?</dt>\s*<dd\b.*?</dd>", bruto, re.S)
            saida.append(
                "\n".join(
                    "- **%s** — %s"
                    % (
                        " ".join(texto(re.search(r"<dt.*?</dt>", p, re.S).group(0)).split()),
                        " ".join(texto(re.search(r"<dd.*?</dd>", p, re.S).group(0)).split()),
                    )
                    for p in pares
                )
            )
        elif tag == "note":
            rotulo = re.search(r'class="lbl">(.*?)</span>', bruto, re.S)
            corpo = re.sub(r'<span class="lbl">.*?</span>', "", bruto, flags=re.S)
            linhas = [texto(p) for p in re.findall(r"<p\b.*?</p>", corpo, re.S)]
            titulo = texto(rotulo.group(1)) if rotulo else "Nota"
            saida.append("> **%s**\n>\n" % titulo + "\n>\n".join("> " + l for l in linhas))
        elif tag == "grid":
            for cel in re.findall(r'<div class="cell">.*?</div>\s*(?=<div|$)', bruto, re.S):
                h6 = re.search(r"<h6>(.*?)</h6>", cel, re.S)
                saida.append(
                    ("**%s** — " % texto(h6.group(1)) if h6 else "")
                    + " ".join(texto(re.sub(r"<h6>.*?</h6>", "", cel, flags=re.S)).split())
                )
        elif tag == "steps":
            for i, st in enumerate(re.findall(r'<div class="step">.*?</div>', bruto, re.S), 1):
                saida.append("%d. %s" % (i, " ".join(texto(st).split())))
        else:  # p
            t = texto(bruto)
            if t:
                saida.append(t)
    return "\n\n".join(x for x in saida if x.strip())


def main(origem: str, destino: str) -> int:
    doc = open(origem, encoding="utf-8").read()
    for t in TAGS_FORA:
        doc = re.sub(r"<%s\b.*?</%s>" % (t, t), "", doc, flags=re.S)
    os.makedirs(destino, exist_ok=True)
    indice, n = [], 0
    for m in re.finditer(r'<section id="(s\d+|anx|trk)"[^>]*>(.*?)</section>', doc, re.S):
        corpo = m.group(2)
        num = re.search(r'class="sec-no">(.*?)</span>\s*<h3>', corpo, re.S)
        tit = re.search(r"<h3>(.*?)</h3>", corpo, re.S)
        if not tit:
            continue
        titulo = " ".join(texto(tit.group(1)).split())
        etiqueta = " ".join(texto(num.group(1)).split()) if num else m.group(1)
        ident = etiqueta.split("—")[0].strip().replace("§", "")
        if not ident.isdigit():
            ident = re.sub(r"\D", "", m.group(1)) or "99"
        nome = "%s-%s.md" % (ident.zfill(2), slug(titulo))
        md = "# %s · %s\n\n_Gerado de %s — nao editar a mao; edita o dossie e volta a correr._\n\n%s\n" % (
            etiqueta,
            titulo,
            os.path.basename(origem),
            bloco(corpo),
        )
        open(os.path.join(destino, nome), "w", encoding="utf-8").write(md)
        indice.append("- [%s · %s](%s)" % (etiqueta, titulo, nome))
        n += 1
    open(os.path.join(destino, "INDEX.md"), "w", encoding="utf-8").write(
        "# Especificacao do Empire\n\nGerado de %s por tools/split_dossie.py.\nA fonte unica e o dossie; estes ficheiros existem para o agente os ler.\n\n%s\n"
        % (os.path.basename(origem), "\n".join(indice))
    )
    print("%d seccoes escritas em %s" % (n, destino))
    return 0


if __name__ == "__main__":
    sys.exit(main(*(sys.argv[1:3] or ["docs/dossie.html", "docs/design"])))
