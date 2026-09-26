#!/usr/bin/env python3
"""Relatorios gerados a partir da base de dados de conteudo (data/source/*.csv).

Uso:  python3 tools/content_report.py            # escreve os dois relatorios
      python3 tools/content_report.py --check    # falha se estiverem desatualizados

Escreve:
  docs/content/PROPOSALS.md  — todos os valores marcados em _proposed, para rever
  docs/content/ROT_BY_DAY.md — a Podridao dia a dia (substitui o waves.csv, §70)

So biblioteca padrao. Nao editar os .md a mao: editar os CSV e voltar a correr.
"""
import csv
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data", "source")
OUT = os.path.join(ROOT, "docs", "content")
HEADER = "_Gerado por tools/content_report.py a partir de data/source/ — nao editar a mao._\n\n"


def rows(table):
    with open(os.path.join(SRC, table + ".csv"), encoding="utf-8") as f:
        return list(csv.DictReader(f))


def tables():
    return [r["table"] for r in rows("_tables")]


def cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


COSMETIC = {"tags", "head_pool", "layer_slots", "shadow_width", "width_px", "icon", "subject", "landmark",
            "weapon_kind", "material_by_people", "food", "growth_stages", "obtain_ref", "expect_suffocation",
            "job_slots", "build_work", "teaches", "playable_class", "starting_units", "starting_buildings",
            "atmosphere_preset", "parallax_preset", "resources", "wildlife", "creature_table", "per_segment_max"}


def collect():
    items = []
    for t in tables():
        data = rows(t)
        key = "key" if data and "key" in data[0] else "id"
        for r in data:
            for field in [f for f in r.get("_proposed", "").split("|") if f]:
                value = r.get(field, "") if key == "id" else r.get("value", "")
                phase = int(r.get("_phase") or 9)
                kind = "apresentação/estrutura" if field in COSMETIC else "balanceamento"
                items.append((t, r[key], field, value, phase, kind, r.get("_notes", "")))
    return items


def proposals_md():
    items = collect()
    vs = [i for i in items if i[4] <= 2]
    out = ["# Valores propostos — para rever\n\n", HEADER,
           "Cada linha é um valor que **não está no dossiê** e foi proposto ao criar a base de dados "
           "(decisão de 11/09/2026: propor e marcar, em vez de deixar vazio). A justificação está na coluna "
           "`_notes` do CSV. Para aceitar um valor, apaga o nome do campo da coluna `_proposed`; para o mudar, "
           "edita o número e mantém a marca até o playtest o confirmar.\n\n",
           "| | balanceamento | apresentação/estrutura | total |\n|---|---|---|---|\n"]
    for label, sel in (("Fases 0–2 (fatia vertical)", vs), ("Fases 3–8", [i for i in items if i[4] > 2]),
                       ("Total", items)):
        b = sum(1 for i in sel if i[5] == "balanceamento")
        out.append("| %s | %d | %d | %d |\n" % (label, b, len(sel) - b, len(sel)))
    out.append("\n**Por onde começar:** a primeira tabela abaixo — os números de balanceamento que a fatia "
               "vertical usa. O resto pode esperar pela fase respetiva.\n\n")
    groups = (("1 · Fatia vertical — balanceamento", lambda i: i[4] <= 2 and i[5] == "balanceamento"),
              ("2 · Fatia vertical — apresentação e estrutura", lambda i: i[4] <= 2 and i[5] != "balanceamento"),
              ("3 · Fases 3 a 8", lambda i: i[4] > 2))
    for title, pred in groups:
        sel = [i for i in items if pred(i)]
        out.append("## %s — %d\n\n| tabela | linha | campo | valor | fase | nota |\n|---|---|---|---|---|---|\n" % (
            title, len(sel)))
        for (t, rid, field, value, phase, kind, note) in sel:
            out.append("| %s | `%s` | `%s` | %s | %s | %s |\n" % (t, rid, field, cell(value), phase, cell(note)))
        out.append("\n")
    return "".join(out)


def rot_md():
    rot = rows("rot")[0]
    # O Zelador (§75) nao e invocado por massa: nasce da Divida da Candeia e custa 0.
    # Fica fora do sorvedouro, senao a conta de invocacoes nunca fecha.
    creatures = sorted([c for c in rows("creatures") if int(c["mass_cost"]) > 0 and not c.get("from_debt")],
                       key=lambda c: int(c["mass_cost"]))
    clock = rows("clock")[0]
    sb, sd = float(rot["speed_base"]), float(rot["speed_per_day"])
    mb, md, mf = float(rot["mass_base"]), float(rot["mass_per_day"]), float(rot["mass_per_fortress"])
    ma, mn = float(rot["mass_per_amargueiro"]), float(rot["mass_per_named_amargueiro"])
    mr, mrw, mrc = float(rot["refusal_mass"]), int(rot["refusal_window_days"]), float(rot["refusal_cap"])
    lo, hi = [float(x) for x in rot["summon_interval"].split("|")]
    pe = int(rot.get("peak_every") or 0)
    pm, cm = float(rot.get("peak_mass_mult") or 1), float(rot.get("calm_mass_mult") or 1)

    def ritmo(d):
        # Q-126: a noite funda de pe em pe noites, e a calma a seguir.
        if pe <= 0:
            return 1.0, ""
        if d % pe == 0:
            return pm, " (funda)"
        if d > 1 and (d - 1) % pe == 0:
            return cm, " (calma)"
        return 1.0, ""
    active = float(clock["dusk"]) + float(clock["night"])
    out = ["# A Podridão, dia a dia\n\n", HEADER,
           "O dossiê não tem ondas: A Podridão é uma entidade com massa (§05, §51), e a §70 acabou com o "
           "`waves/`. Esta tabela é o que o `waves.csv` do relatório mestre pedia, derivada dos dados em vez de "
           "escrita à mão — muda o `rot.csv` ou o `creatures.csv` e volta a correr a ferramenta.\n\n",
           "- Velocidade `v = %g + %g × dia` px/s\n" % (sb, sd),
           "- Massa (§74, termo a termo) `M = %g + %g × dia + %g × fortalezas + %g × amargueiros + "
           "%g × amargueiros nomeados + %g × min(recusas nas últimas %d noites, 5)`, recusas com teto de %g\n" % (
               mb, md, mf, ma, mn, mr, mrw, mrc),
           "- O que a tabela mostra é o **piso**: só os dois primeiros termos. A base e o termo do dia desceram "
           "de propósito na §74 — o que a noite tem de duro deixa de vir do calendário e passa a vir de como "
           "jogaste. Duas árvores deixadas de pé (+%g) valem mais do que um dia inteiro (+%g).\n" % (2 * ma, md),
           "- O Zelador (§75) não entra nesta conta: não é invocado por massa, nasce da Dívida da Candeia ≥ %s\n" % (
               rot["tender_from_debt"]),
           "- Invoca a cada %g–%g s enquanto está ativa: crepúsculo + noite = %g s → **%d a %d invocações** no máximo\n" % (
               lo, hi, active, math.floor(active / hi), math.floor(active / lo)),
           "- Escolha (§51): a criatura **mais cara que cabe** na massa e cujo dia mínimo já passou\n",
           "- Lado duplo a partir do dia %s\n" % rot["two_sided_from_day"],
           "- Ritmo (Q-126): de %d em %d noites uma **funda** (massa × %g), e a seguinte **calma** (× %g). "
           "O lado de cada noite diz-se à tarde (Q-125)\n\n" % (pe, pe, pm, cm),
           "| dia | velocidade px/s | massa (0 fort.) | massa (2 fort.) | criatura mais cara disponível | "
           "invocações até esgotar (0 fort.) | lados |\n|---|---|---|---|---|---|---|\n"]
    for d in range(1, 31):
        mult, nota = ritmo(d)
        mass = (mb + md * d) * mult
        avail = [c for c in creatures if int(c["min_day"]) <= d]
        top = max(avail, key=lambda c: int(c["mass_cost"]))
        m, n = mass, 0
        while True:
            fit = [c for c in avail if int(c["mass_cost"]) <= m]
            if not fit:
                break
            m -= int(max(fit, key=lambda c: int(c["mass_cost"]))["mass_cost"])
            n += 1
        sides = "2" if d >= int(rot["two_sided_from_day"]) else "1"
        out.append("| %d%s | %.1f | %g | %g | %s (%s) | %d | %s |\n" % (
            d, nota, sb + sd * d, round(mass, 1), round(mass + 2 * mf * mult, 1), top["id"],
            top["mass_cost"], n, sides))
    out.append("\n**Leitura:** a coluna \"invocações até esgotar\" é o que a massa paga; o tempo ativo limita-a "
               "a %d–%d. Quando a primeira passa a segunda, sobra massa ao amanhecer — a noite deixa de ser limitada "
               "pela massa e passa a ser limitada pelo relógio. Ver Q-017 em docs/QUESTIONS.md.\n" % (
                   math.floor(active / hi), math.floor(active / lo)))
    return "".join(out)


def exports(script_path):
    """Le as propriedades exportadas de um Resource GDScript: nome -> (tipo, comentario, grupo)."""
    import re
    out, group = {}, ""
    path = os.path.join(ROOT, script_path.replace("res://", ""))
    text = re.sub(r"@export\s*\n\s*var ", "@export var ", open(path, encoding="utf-8").read())
    for line in text.splitlines():
        g = re.match(r'@export_group\("([^"]*)"\)', line)
        if g:
            group = g.group(1)
        m = re.match(r"@export var (\w+): ([^=#]+?)(?:\s*=\s*[^#]*)?(?:#\s*(.*))?$", line.strip())
        if m:
            out[m.group(1)] = (m.group(2).strip(), (m.group(3) or "").strip(), group)
    return out


def schema_md():
    out = ["# Esquema da base de dados de conteúdo\n\n", HEADER,
           "Uma secção por tabela de `data/source/_tables.csv`: cada coluna do CSV, o tipo da propriedade no "
           "`Resource`, e o grupo. Colunas `_` são documentação e não aparecem aqui. Os campos do grupo "
           "**v5.2** foram acrescentados à §44 pela base de dados — ver docs/content/CONTENT_DATABASE.md.\n\n"]
    for t in rows("_tables"):
        props = exports(t["script"])
        data = rows(t["table"])
        cls = os.path.basename(t["script"]).replace(".gd", "")
        out.append("## `%s.csv` → `%s`\n\n" % (t["table"], t["out"].replace("res://", "")))
        out.append("Script `%s` · layout `%s` · %d linha(s) · %s\n\n" % (
            t["script"].replace("res://", ""), t["layout"], len(data), t.get("_notes", "")))
        out.append("| coluna | tipo | grupo | nota do script |\n|---|---|---|---|\n")
        groups = {}
        for spec in [g for g in t.get("groups", "").split(";") if g]:
            target, cols = spec.split("=")
            for c in cols.split("+"):
                groups[c] = target
        cols = [r["key"] for r in data] if t["layout"] == "kv" else [c for c in (data[0].keys() if data else []) if not c.startswith("_")]
        for c in cols:
            if c in groups:
                typ, note, grp = props.get(groups[c], ("?", "", ""))
                out.append("| `%s` | elemento de `%s` (%s) | %s | %s |\n" % (c, groups[c], typ, grp, cell(note)))
            elif c in props:
                typ, note, grp = props[c]
                out.append("| `%s` | %s | %s | %s |\n" % (c, typ, grp, cell(note)))
            elif c == "id":
                out.append("| `id` | nome do ficheiro | — | o recurso não tem campo id |\n")
            else:
                out.append("| `%s` | **sem propriedade** | — | a ferramenta vai falhar |\n" % c)
        out.append("\n")
    return "".join(out)


def names_md():
    """Todos os nomes de conteudo: id interno, chave, PT-PT e EN — de strings.csv e das tabelas."""
    with open(os.path.join(ROOT, "data", "i18n", "strings.csv"), encoding="utf-8") as f:
        strings = {r["keys"]: r for r in csv.DictReader(f)}
    out = ["# Nomes — id, chave, PT-PT, EN\n\n", HEADER,
           "A fonte dos nomes visíveis é `data/i18n/strings.csv`; a dos ids é cada tabela de `data/source/`. "
           "Esta página junta as duas para a Bíblia de nomes (docs/content/NAMING_BIBLE.md). "
           "Nomes de povos e do jogo são **provisórios** (§04, §36).\n\n"]
    for t in tables():
        data = rows(t)
        if not data or "display_key" not in data[0]:
            continue
        out.append("## %s\n\n| id | chave | PT-PT | EN |\n|---|---|---|---|\n" % t)
        for r in data:
            s_ = strings.get(r["display_key"], {})
            out.append("| `%s` | `%s` | %s | %s |\n" % (r["id"], r["display_key"], cell(s_.get("pt_PT", "—")), cell(s_.get("en", "—"))))
        out.append("\n")
    return "".join(out)


def main():
    check = "--check" in sys.argv
    docs = {"PROPOSALS.md": proposals_md(), "ROT_BY_DAY.md": rot_md(), "SCHEMA.md": schema_md(), "NAMES.md": names_md()}
    stale = []
    os.makedirs(OUT, exist_ok=True)
    for name, text in docs.items():
        path = os.path.join(OUT, name)
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if check:
            if old != text:
                stale.append(name)
        else:
            open(path, "w", encoding="utf-8").write(text)
            print("escrito", os.path.relpath(path, ROOT))
    if stale:
        print("desatualizados (corre sem --check):", ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
