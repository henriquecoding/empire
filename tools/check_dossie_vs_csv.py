#!/usr/bin/env python3
"""Confere os numeros das tabelas do dossie contra data/source/*.csv.

Uso:  python3 tools/check_dossie_vs_csv.py [docs/dossie.html]

O dossie manda no design e no balanceamento (§39); os CSV sao a fonte do jogo (§44).
Este guiao apanha o dia em que um e editado e o outro nao. So biblioteca padrao.
Cada verificacao diz de que tabela do dossie vem; falha com exit 1 se algo divergir.
"""
import csv
import os
import re
import sys
from html.parser import HTMLParser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Tables(HTMLParser):
    """Recolhe todas as tabelas, com o id da seccao em que estao."""

    def __init__(self):
        super().__init__()
        self.section, self.tables, self.row, self.cell = None, [], None, None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "section" and a.get("id"):
            self.section = a["id"]
        elif tag == "table":
            self.tables.append((self.section, []))
        elif tag == "tr" and self.tables:
            self.row = []
        elif tag in ("td", "th") and self.row is not None:
            self.cell = []

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.cell is not None:
            self.row.append(" ".join("".join(self.cell).split()))
            self.cell = None
        elif tag == "tr" and self.row is not None:
            self.tables[-1][1].append(self.row)
            self.row = None

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)


def num(text):
    m = re.search(r"-?\d+(?:[.,]\d+)?", text.replace("−", "-"))
    return float(m.group(0).replace(",", ".")) if m else None


def rng(text):
    m = re.search(r"(\d+)\s*[–-]\s*(\d+)", text)
    return (int(m.group(1)), int(m.group(2))) if m else None


def csv_rows(table):
    with open(os.path.join(ROOT, "data", "source", table + ".csv"), encoding="utf-8") as f:
        return {r["id"]: r for r in csv.DictReader(f)}


def find(tables, section, first_header):
    for sec, rows in tables:
        if sec == section and rows and rows[0] and rows[0][0].startswith(first_header):
            return rows
    raise SystemExit("tabela nao encontrada: %s / %s" % (section, first_header))


# (seccao, primeira coluna do cabecalho, csv, {nome no dossie: id}, {coluna do dossie: campo do csv})
CHECKS = [
    ("s07", "Unidade", "units",
     {"Vagabundo": "vagrant", "Arqueiro": "archer", "Lanceiro": "spearman", "Libélula": "dragonfly",
      "Berserker de Raiz": "root_berserker", "Mercenário": "mercenary"},
     {"Custo": "recruit_cost", "Vida": "max_health", "Dano": "damage", "Interv.": "attack_interval",
      "Alcance": "range_px"}),
    ("s07", "Criatura", "creatures",
     {"Rastejante": "crawler", "Alado": "winged", "Bruto": "brute", "Cavador": "burrower",
      "Aríete de lodo": "slime_ram", "Consumidora": "devourer"},
     {"Massa": "mass_cost", "Vida": "max_health", "Dano": "damage", "Interv.": "attack_interval",
      "Vel.": "move_speed", "Aparece a partir do": "min_day"}),
    ("s06", "Fonte", "buildings",
     {"Plantação": "farm", "Pesqueiro": "fishery", "Galinheiro": "henhouse", "Estábulo de vaca": "cow_stable",
      "Corte de madeira": "lumber_camp", "Poço de minério": "ore_pit"},
     {"Custo": "cost", "Se vender": "yield_per_day"}),
    ("s06", "Matéria", "buildings",
     {"Grão": "granary", "Peixe": "saltery", "Animal vivo": "pen", "Madeira": "sawmill", "Minério": "smelter"},
     {"Custo": "cost"}),
    ("s10", "Nível", "walls",
     {"Estacaria": "stakes", "Paliçada": "palisade", "Muro de pedra": "stone_wall",
      "Muralha de ferro": "iron_wall", "Bastião": "bastion"},
     {"Custo": "cost", "Vida (B)": "max_health_b", "Postos (A)": "guard_posts_a",
      "Slots de contacto": "contact_slots"}),
    ("s10", "Estrutura", "buildings",
     {"Torre de arqueiros": "archer_tower", "Torre alta": "high_tower", "Barril de fogo": "fire_barrel",
      "Fosso de raízes": "root_moat", "Farol": "lighthouse", "Altar consagrado": "consecrated_altar"},
     {"Custo": "cost"}),
    ("s12", "Montaria", "mounts",
     {"A pé": "on_foot", "Cavalo de tração": "draft_horse", "Javali": "boar", "Lagarto": "lizard",
      "Libélula": "dragonfly_mount", "Alce da Podridão": "rot_elk"},
     {"Velocidade": "speed_multiplier"}),
    ("s09", "Ofício", "units",
     {"Construtor": "builder", "Ferreiro": "smith", "Cozinheiro": "cook", "Diplomata": "diplomat",
      "Bardo": "bard"},
     {"Treino": "recruit_cost"}),
]


# ---------------------------------------------------------------- Parte XIII

OFERTAS = {
    "Dá-me o que já não anda": "the_lame",
    "Nada. Só quero ver": "just_looking",
    "Um por cada porta": "one_per_door",
    "Deixa a porta aberta": "open_gate",
    "O que brilha, e nada mais": "all_that_shines",
    "A árvore que plantaste": "the_tree_you_planted",
    "Diz-me um nome": "tell_me_a_name",
    "O que enterraste": "what_you_buried",
    "O que estava aqui antes de ti": "what_was_here_before",
    "Fica com a candeia por uma noite": "keep_the_lantern",
    "Um herdeiro": "an_heir",
    "Devolve-me o que é meu": "give_back_whats_mine",
}

FEITOS = {
    "Aguentou": "the_one_who_stayed",
    "Último na porta": "she_who_held_the_gate",
    "Partiu o cerco": "the_one_who_broke_stone",
    "Contou": "the_counter",
    "Trouxe os outros": "the_one_who_brought_the_others",
    "Falou com ela": "she_who_spoke_with_her",
    "Não comeu": "the_dry_one",
    "Voltou": "she_who_came_back",
    "Não largou": "the_one_with_the_same_spear",
}

# §74: quantos Amargueiros anonimos e nomeados cada linha da tabela assume.
CAMPO = {"Campo limpo": (0, 0), "3 Amargueiros": (3, 0), "8 Amargueiros": (8, 0),
         "5 anónimos": (5, 3)}

DESTINOS = {"Cortar": "fell", "Consagrar": "consecrate", "Deixar": "leave"}


def sem_refs(text):
    """Tira as referencias §NN, senao o numero da seccao entra na conta."""
    return re.sub(r"§\s*\d+", "", text)


def numeros(text):
    """Todos os numeros de uma celula, virgula decimal incluida."""
    return [float(x.replace(",", ".")) for x in
            re.findall(r"-?\d+(?:[.,]\d+)?", sem_refs(text).replace("−", "-"))]


def parte_xiii(tables, problems, texto_cru):
    """As tabelas da Parte XIII (§74 a §80) contra rot/amargueiros/offers/titles/clock."""
    n = 0
    rot = csv_rows("rot")["default"]
    mb, md = float(rot["mass_base"]), float(rot["mass_per_day"])
    ma, mn = float(rot["mass_per_amargueiro"]), float(rot["mass_per_named_amargueiro"])

    # §74 · a massa termo a termo, dia 5 / 10 / 20
    massa = find(tables, "s74", "Estado do campo")
    dias = [int(num(c)) for c in massa[0][1:4]]
    for r in massa[1:]:
        chave = next((k for k in CAMPO if r[0].startswith(k)), None)
        if chave is None:
            continue  # a linha de referencia da v5.2 nao sai do rot.csv atual
        anon, nomeados = CAMPO[chave]
        for coluna, dia in enumerate(dias, start=1):
            n += 1
            quer = num(r[coluna])
            tem = mb + md * dia + ma * anon + mn * nomeados
            if abs(tem - quer) > 1e-6:
                problems.append("§74 %s · dia %d: dossie %g, rot.csv da %g" % (chave, dia, quer, tem))

    # §74 · os tres destinos
    destinos = find(tables, "s74", "Destino")
    amg = csv_rows("amargueiros")
    for r in destinos[1:]:
        chave = next((k for k in DESTINOS if r[0].startswith(k)), None)
        if chave is None:
            continue
        rec = amg[DESTINOS[chave]]
        n += 1
        custo = num(r[2])
        campo = "cost_seeds" if "Semente" in r[2] else "cost_coins"
        if custo is not None and abs(float(rec[campo]) - custo) > 1e-6:
            problems.append("§74 %s · custo: dossie %g, amargueiros.csv %s=%s" % (
                chave, custo, campo, rec[campo]))
        n += 1
        efeito = numeros(r[4])
        if efeito and abs(abs(efeito[0]) - abs(float(rec["mass_delta"]))) > 1e-6:
            problems.append("§74 %s · efeito na massa: dossie %g, amargueiros.csv mass_delta=%s" % (
                chave, efeito[0], rec["mass_delta"]))

    # §74 · o raio da candeia, que esta numa lista e nao numa tabela
    m = re.search(r"(\d+)\s*\+\s*(\d+)\s*×\s*dia px, com teto em\s*(\d+)", texto_cru)
    if m is None:
        problems.append("§74: nao encontrei a linha do raio da candeia no dossie")
    else:
        for quer, campo in zip(m.groups(), ("lantern_radius_base", "lantern_radius_per_day",
                                            "lantern_radius_max")):
            n += 1
            if abs(float(rot[campo]) - float(quer)) > 1e-6:
                problems.append("§74 candeia · %s: dossie %s, rot.csv %s" % (campo, quer, rot[campo]))

    # §75 · as doze ofertas: quando e quanto pesa na Divida
    ofertas = find(tables, "s75", "A frase")
    off = csv_rows("offers")
    for r in ofertas[1:]:
        chave = next((k for k in OFERTAS if r[0].startswith(k)), None)
        if chave is None:
            continue
        rec = off[OFERTAS[chave]]
        n += 1
        divida = num(r[4])
        if divida is None:  # "fecha": a decima segunda acaba o ciclo
            if rec["ends_rot"] != "true":
                problems.append("§75 %s: dossie diz 'fecha', offers.csv ends_rot=%s" % (chave, rec["ends_rot"]))
        elif abs(float(rec["debt_delta"]) - divida) > 1e-6:
            problems.append("§75 %s · divida: dossie %g, offers.csv debt_delta=%s" % (
                chave, divida, rec["debt_delta"]))
        if r[3].startswith("Dia"):
            n += 1
            dia = num(r[3])
            if abs(float(rec["min_day"]) - dia) > 1e-6:
                problems.append("§75 %s · quando: dossie dia %g, offers.csv min_day=%s" % (
                    chave, dia, rec["min_day"]))

    # §75 · os limiares da Divida da Candeia
    divida = find(tables, "s75", "Dívida")
    limiares = []
    for r in divida[1:]:
        ns = numeros(r[0])
        if ns and ns[0] > 0:
            limiares.append(int(ns[0]))
    n += 1
    csv_lim = [int(x) for x in rot["debt_tiers"].split("|")]
    if limiares != csv_lim:
        problems.append("§75 limiares da Divida: dossie %s, rot.csv debt_tiers=%s" % (limiares, csv_lim))
    for campo, indice, rotulo in (("tender_from_debt", 1, "Zelador"),
                                  ("ambient_light_from_debt", 2, "luz ambiente"),
                                  ("second_flame_from_debt", 3, "segunda chama")):
        n += 1
        if indice < len(limiares) and int(rot[campo]) != limiares[indice]:
            problems.append("§75 %s: dossie %s, rot.csv %s=%s" % (
                rotulo, limiares[indice], campo, rot[campo]))

    # §76 · os nove feitos
    feitos = find(tables, "s76", "Feito")
    tit = csv_rows("titles")
    for r in feitos[1:]:
        chave = next((k for k in FEITOS if r[0].startswith(k)), None)
        if chave is None:
            continue
        quer = num(sem_refs(r[1]))
        if quer is None:
            continue  # condicao sem numero: "unico sobrevivente", "golpe final"
        n += 1
        rec = tit[FEITOS[chave]]
        if abs(float(rec["condition_value"]) - quer) > 1e-6:
            problems.append("§76 %s · condicao: dossie %g, titles.csv condition_value=%s" % (
                chave, quer, rec["condition_value"]))

    # §80 · o tint de cada fase, matiz · saturacao · valor
    tint = find(tables, "s80", "Fase")
    clock = csv_rows("clock")["default"]
    fases = ["dawn", "morning", "noon", "afternoon", "dusk", "night"]
    hue = [float(x) for x in clock["phase_tint_hue"].split("|")]
    sat = [float(x) for x in clock["phase_tint_sat"].split("|")]
    val = [float(x) for x in clock["phase_tint_val"].split("|")]
    for i, r in enumerate(tint[1:]):
        if i >= len(fases):
            break
        ns = numeros(r[2])
        if len(ns) < 3:
            continue
        for quer, tem, rotulo in ((ns[0], hue[i], "matiz"), (ns[1], sat[i], "saturacao"),
                                  (ns[2], val[i], "valor")):
            n += 1
            if abs(tem - quer) > 1e-6:
                problems.append("§80 %s · %s: dossie %g, clock.csv %g" % (fases[i], rotulo, quer, tem))
    return n


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "dossie.html")
    parser = Tables()
    bruto = open(path, encoding="utf-8").read()
    parser.feed(bruto)
    problems, checked = [], 0
    for section, first, table, names, cols in CHECKS:
        rows = find(parser.tables, section, first)
        header, data = rows[0], csv_rows(table)
        for r in rows[1:]:
            label = next((n for n in names if r[0].startswith(n)), None)
            if label is None:
                continue
            rec = data[names[label]]
            for col, field in cols.items():
                want = num(r[header.index(col)])
                if want is None:
                    continue  # "—" ou "variável": o dossie nao da numero
                checked += 1
                got = num(rec[field])
                if got is None or abs(got - want) > 1e-6:
                    problems.append("§%s %s · %s: dossie %s, %s.csv %s=%s" % (
                        section[1:], label, col, want, table, field, rec[field]))
    phases = find(parser.tables, "s05", "Fase")
    clock = csv_rows("clock")["default"]
    for r, col in zip(phases[1:], ["dawn", "morning", "noon", "afternoon", "dusk", "night"]):
        checked += 1
        if num(r[1]) != float(clock[col]):
            problems.append("§05 %s: dossie %s, clock.csv %s=%s" % (r[0], r[1], col, clock[col]))
    greed = find(parser.tables, "s15", "Perfil")
    ids = {"Austero": "austere", "Equilibrado": "balanced", "Fastuoso": "lavish", "Tirano": "tyrant"}
    data = csv_rows("greed_profiles")
    for r in greed[1:]:
        checked += 1
        want, got = rng(r[1]), tuple(int(x) for x in data[ids[r[0]]]["greed_range"].split("|"))
        if want != got:
            problems.append("§15 %s: dossie %s, greed_profiles.csv %s" % (r[0], want, got))
    checked += parte_xiii(parser.tables, problems, bruto)
    for p in problems:
        print("DIVERGE", p)
    print("check_dossie_vs_csv: %d valores conferidos, %d divergencia(s)" % (checked, len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
