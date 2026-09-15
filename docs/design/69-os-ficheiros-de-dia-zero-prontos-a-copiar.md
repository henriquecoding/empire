# 69 — Arranque · novo · Os ficheiros de dia zero, prontos a copiar

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Onze ficheiros, quase todos abaixo das trinta linhas. Copia-os por esta ordem, faz um commit por onda, e o repositório fica com todos os portões antes de existir uma linha de lógica de jogo. O último — o split do dossiê — é o que fecha as referências penduradas da §68.

## 1 · .gitignore

```gdscript
# ---- Godot 4 ----
.godot/                 # cache do editor: nunca vai para o repositorio
/android/
/build/
/export/
*.translation           # gerado de data/i18n/*.csv

# ---- Arte gerada ----
# A fonte esta em art/source/ (LFS). art/export/ e produzido pelo Aseprite Wizard.
art/export/
!art/export/_placeholder/
!art/export/_placeholder/**

# ---- Dados gerados por tools/csv_to_tres.gd ----
# ADR 0004: os .tres SAO versionados — o export precisa deles e o CI nao tem de
# correr a ferramenta. Se algum dia inverteres a decisao, descomenta:
# data/**/*.tres
# !data/source/**

# ---- Segredos ----
# O export_presets.cfg E versionado. Palavras-passe de keystore e credenciais
# de assinatura ficam em variaveis de ambiente / segredos do GitHub, nunca aqui.
*.keystore
*.p12
.env

# ---- Sistema ----
.DS_Store
Thumbs.db
*.tmp
```

## 2 · .gitattributes

Uma armadilha conhecida: em .gitattributes ganha a última regra que casa, não a primeira. A linha dos addons/ tem de vir depois das de LFS, ou os ícones do gdUnit4 acabam a gastar a tua quota.

```gdscript
* text=auto eol=lf

# ---- Git LFS, desde o primeiro commit (§28) ----
*.aseprite      filter=lfs diff=lfs merge=lfs -text
*.ase           filter=lfs diff=lfs merge=lfs -text
art/**/*.png    filter=lfs diff=lfs merge=lfs -text
audio/**/*.ogg  filter=lfs diff=lfs merge=lfs -text
audio/**/*.wav  filter=lfs diff=lfs merge=lfs -text

# Os addons trazem PNGs pequenos e nao devem ir para LFS.
# Em .gitattributes a ultima regra que casa e a que vale — por isso vem depois.
# v5.2: 'text' forcado corrompia os PNG dos addons; '!' repoe o valor por omissao (C-05, §72)
addons/**       !filter !diff !merge text=auto

# Ficheiros do Godot sao texto: tem de dar diff legivel numa revisao
*.gd    text eol=lf
*.tres  text eol=lf
*.tscn  text eol=lf
*.godot text eol=lf
```

## 3 · AGENTS.md — o contrato

```gdscript
# Empire — contrato do agente

Vale para qualquer agente. O CLAUDE.md tem tres linhas a apontar para aqui.
Se leres um unico ficheiro deste repositorio, e este.

## O que e
Kingdom-builder 2D em pixel art. Godot 4.6, GDScript. Mundo 1.5D com tres
faixas verticais: AERIAL, SURFACE, UNDERGROUND.

## Onde esta a verdade
- Design e especificacao: docs/design/ — um ficheiro por seccao, gerado do
  dossie por tools/split_dossie.py. NAO editar a mao.
- Decisoes tomadas, e porque: docs/adr/
- A tarefa desta sessao: docs/backlog/<id>.md
- Duvida que a spec nao cobre: escreve-a em docs/QUESTIONS.md. Nao decidas tu.
- Asset em falta: placeholder de cor lisa em art/export/_placeholder/ e uma
  linha em docs/ASSETS_TODO.md.

## Regras absolutas
1. Maximo 250 linhas por script. O gdlint chumba — nao e um conselho.
2. src/sim/ nao importa de nenhuma camada acima e nao usa Node, Node2D nem
   qualquer classe de cena. E logica pura. Posicao entra como parametro.
3. Balanceamento vive em data/**/*.tres, gerado de data/source/*.csv.
   Nunca escrevas um numero de balanceamento dentro de um script.
4. Toda a funcao publica de src/sim/ tem teste em tests/. O teste vem primeiro.
5. Tipos sempre anotados: func f(x: int) -> void. Sem excecoes.
6. Aleatoriedade so pelo RngService, com fluxo nomeado. Nunca randi, randf
   nem randomize fora de src/core/rng_service.gd.
7. Sinais: so os que existem no catalogo (docs/design/46-*.md).
8. Sem dependencias novas sem uma ADR em docs/adr/.
9. Nao toques em art/ nem em audio/.

## Vocabulario — codigo em ingles, dossie em portugues
Band -> faixa (AERIAL|SURFACE|UNDERGROUND) · Rot -> A Podridao ·
People -> povo (Enramados, Portuarios, Fenda, Horta, Fornalha, SobRaiz) ·
Craft -> oficio (builder, smith, cook, diplomat, bard) · Boost -> impulso ·
Greed -> ganancia (0-100) · RoyalSeed -> Semente Real · Favor -> favor

## Caminhos canonicos — se dois documentos divergirem, esta tabela manda
src/sim/band.gd             Band          enum, planos de imagem, GROUND_LINE
src/sim/game_clock.gd       GameClock     relogio puro (RefCounted)
src/core/clock_service.gd   ClockService  autoload; faz o relogio andar
src/world/band_layers.gd    BandLayers    camadas e mascaras de fisica
src/world/camera_rig.gd     CameraRig     camara unica
scenes/boot.tscn                          cena principal do project.godot

## Ciclo de trabalho
1. Le docs/backlog/<id>.md e as seccoes de docs/design/ que ele cita.
2. Escreve ou atualiza o teste em tests/. Confirma que falha.
3. Implementa o minimo que o faz passar.
4. Corre ./run_tests.sh
5. So com tudo verde, propoe o diff, com a checklist do PR preenchida.

## O que nao fazer
- Nao inventes mecanicas. Se a spec nao cobre o caso, escreve a pergunta em
  docs/QUESTIONS.md e implementa a opcao mais simples e mais reversivel.
- Nao refatores fora do ambito da tarefa.
- Nao escrevas comentarios que repetem o codigo.
- Nao uses load() em ficheiros de save. Ver docs/adr/0007-save-security.md
- Nao mudes um numero em data/ para fazer um teste de design passar. Um teste
  de design a falhar e informacao, nao um obstaculo.
```

### E o CLAUDE.md passa a isto

```gdscript
# Empire

Este repositorio usa **AGENTS.md** como contrato unico do agente.
Le AGENTS.md antes de qualquer tarefa — nao ha aqui nenhuma regra que
nao esteja la.
```

> **Porque é AGENTS.md e não CLAUDE.md**
>
> O contrato é do repositório, não da ferramenta. Um ficheiro neutro com um ponteiro de três linhas por cima deixa-te trocar de assistente a meio de uma fase — ou usar dois ao mesmo tempo, um a escrever e outro a rever — sem reescrever nada nem manter duas cópias que divergem. A partir daí, a diferença entre ferramentas passa a ser de execução e de preço, que é onde deve estar, e nunca de regras do projeto.

## 4 · .github/workflows/ci.yml

Três coisas que a versão do §31 não tinha: a versão do motor fixada, o passo --import, e o export a correr em cada push.

```gdscript
name: ci
on: [push, pull_request]

env:
  GODOT_VERSION: 4.6-stable

jobs:
  testes:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: false                      # a suite nao precisa de arte

      - name: Godot ${{ env.GODOT_VERSION }}
        run: |
          BASE=https://github.com/godotengine/godot-builds/releases/download
          F=Godot_v${GODOT_VERSION}_linux.x86_64
          curl -sSLo godot.zip $BASE/${GODOT_VERSION}/${F}.zip
          unzip -q godot.zip && chmod +x $F && sudo mv $F /usr/local/bin/godot

      # Sem este passo a suite falha sempre em checkout frio: o Godot precisa
      # de importar os recursos uma vez antes de conseguir abrir uma cena.
      - name: Importar recursos
        run: godot --headless --import --path . || true

      - name: G2 · nenhum RNG solto fora do RngService
        run: |
          ! grep -rnE '\b(randi|randf|randomize|randi_range|randf_range)\s*\(' \
              src/ --include='*.gd' | grep -v 'src/core/rng_service.gd'

      - name: G1 G3 G4 G5 · suite gdUnit4
        # v5.2: o gdUnit4 6.x sai com 103 em --headless sem esta opcao (C-03, §72)
        run: godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests

      - name: Formato e limite de 250 linhas
        run: |
          pipx install "gdtoolkit==4.*"
          gdformat --check src/ tests/ tools/
          gdlint src/ tests/

      # v5.2: sem templates o export falha sempre; so os de Linux, em cache (C-04, §72)
      - name: Cache dos templates de export
        uses: actions/cache@v4
        with:
          path: ~/.local/share/godot/export_templates
          key: godot-templates-${{ env.GODOT_VERSION }}-linux

      - name: Templates de export (so Linux)
        run: |
          T=~/.local/share/godot/export_templates/${GODOT_VERSION/-/.}
          if [ ! -f "$T/linux_debug.x86_64" ]; then
            mkdir -p "$T"
            BASE=https://github.com/godotengine/godot-builds/releases/download
            curl -sSLo t.tpz $BASE/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz
            unzip -q -j t.tpz templates/linux_debug.x86_64 templates/linux_release.x86_64 \
              templates/version.txt -d "$T"
            rm t.tpz
          fi

      - name: Export do Linux ainda arranca
        run: |
          mkdir -p build
          godot --headless --path . --export-debug "Linux" build/empire.x86_64
          test -s build/empire.x86_64 && test -s build/empire.pck
          cd build && ./empire.x86_64 --headless --quit-after 30
```

> **O passo --import — meia manhã perdida, uma vez por projeto**
>
> Num checkout frio não existe .godot/, e portanto não existe nenhum recurso importado. Qualquer teste que abra uma cena falha com um erro que não menciona importação nenhuma. Toda a gente perde a mesma meia manhã a descobrir isto; tu já não tens de a perder.

## 5 · run_tests.sh

```gdscript
#!/usr/bin/env bash
# O unico comando de testes. Usa-o tu e usa-o o agente: assim ha um so sitio
# para mudar quando o gdUnit4 mudar de caminho.
set -euo pipefail
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import --path . >/dev/null 2>&1 || true
# v5.2: o gdUnit4 6.x recusa --headless sem --ignoreHeadlessMode (sai com 103). C-03, §72
"$GODOT" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests "$@"
```

## 6 · .github/PULL_REQUEST_TEMPLATE.md

```gdscript
## Tarefa
docs/backlog/<id>.md

## Checklist — le-se antes do diff, nao depois
- [ ] Nenhum ficheiro passa das 250 linhas
- [ ] Nada em src/sim/ importa de cima nem usa Node / Node2D
- [ ] Zero numeros de balanceamento no codigo (estao em data/)
- [ ] Todas as funcoes publicas anotadas: func f(x: int) -> void
- [ ] Ha teste novo, e ele falhava antes desta alteracao
- [ ] Os sinais usados existem no catalogo da §46
- [ ] RNG so pelo RngService, com fluxo nomeado
- [ ] Nada refatorado fora do ambito da tarefa
- [ ] Se surgiu uma duvida de design, esta em docs/QUESTIONS.md

## O que este PR NAO faz
<uma linha — e o campo que impede tres tarefas no mesmo diff>
```

## 7 · docs/adr/0000-template.md

```gdscript
# ADR NNNN — <titulo curto na forma de decisao>

- Estado: proposta | aceite | substituida por ADR NNNN
- Data: AAAA-MM-DD
- Seccao do dossie: §NN

## Contexto
O que era verdade quando esta decisao foi tomada. Restricoes reais, nao desejos.

## Decisao
Uma frase no presente e no imperativo. "O relogio e puro; o autoload so o faz andar."

## Alternativas consideradas
O que foi rejeitado, e a razao concreta.

## Consequencias
O que fica mais facil. O que fica mais dificil. O que passa a ser proibido.
Se esta decisao for revertida, o que tem de ser reescrito.
```

E os sete primeiros, a escrever na Fase 0 — o 0007 já é citado como regra absoluta no contrato:

| ADR | Decisão | Vem de |
| --- | --- | --- |
| 0001 | Escala e escada de resoluções: fractional por omissão, interruptor para integer | §19 |
| 0002 | Três faixas com camadas de física separadas, desde a primeira entidade | §53 |
| 0003 | Balanceamento em CSV, gerado para .tres | §44 |
| 0004 | Os .tres gerados são versionados | novo, §69 |
| 0005 | boot.tscn é a cena principal; game.tscn é instanciada por ela | §70 |
| 0006 | O relógio é puro; o autoload só o faz andar | §70 |
| 0007 | O save nunca usa load(): só tipos base, validados campo a campo | §62 |


## 8 · .editorconfig e .gdlintrc

```gdscript
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.gd]
indent_style = tab          # convencao do GDScript; o gdformat assume-a
indent_size = 4

[*.{yml,yaml,json,md,csv,cfg}]
indent_style = space
indent_size = 2
```

```gdscript
# .gdlintrc — gdtoolkit 4.x
max-line-length: 100
max-file-lines: 250            # a regra do §28 deixa de ser boa intencao
max-public-methods: 20
function-arguments-number: 6
# v5.2: '_?' aceita privados (_init, _durations), que o GameClock do §30 usa (C-02, §72)
function-name: '(_on_)?_?[a-z][a-z0-9]*(_[a-z0-9]+)*'
class-variable-name: '_?[a-z][a-z0-9]*(_[a-z0-9]+)*'
```

> **A linha que vale a secção inteira**
>
> max-file-lines: 250. A regra mais valiosa do §28 — a que faz um agente escrever código revisível — deixa de depender de alguém se lembrar dela e passa a chumbar no CI. Custo: uma linha.

## 9 · Os dois ficheiros de uma linha

```gdscript
.godot-version          ->  4.6-stable
art/source/.gdignore    ->  (ficheiro vazio)
```

O .gdignore impede o Godot de tentar importar .aseprite e de reimportar a pasta inteira a cada checkout de LFS. O .godot-version fixa o motor: sem ele, um patch do Godot a meio da Fase 3 muda um resultado de teste e passas dois dias à procura de um bug que não existe.

## 10 · src/sim/data/clock_data.gd e o primeiro CSV

```gdscript
# src/sim/data/clock_data.gd
# O Resource que o construtor do GameClock recebe (§30) e que a v5 nao criava.
class_name ClockData
extends Resource

## Alvorada, manha, meio-dia, tarde, crepusculo, noite — em segundos reais.
@export var phase_durations: PackedFloat32Array = PackedFloat32Array(
	[15.0, 85.0, 40.0, 85.0, 30.0, 105.0]
)

## Redundante de proposito: o teste compara com a soma e chumba se divergirem.
@export var day_seconds: float = 360.0

@export var tick_hz: int = 30
```

```gdscript
id,dawn,morning,noon,afternoon,dusk,night,tick_hz
default,15,85,40,85,30,105,30
```

Duas linhas de CSV chegam para provar o circuito inteiro — data/source/clock.csv → tools/csv_to_tres.gd → data/economy/clock.tres → ClockService — no primeiro dia, em vez de o descobrires partido quando tiveres sete folhas de cálculo para converter.

## 11 · tools/split_dossie.py

O ficheiro que fecha a maior lacuna da §68: transforma este dossiê nos 75 ficheiros de docs/design/ que o contrato manda o agente ler. Só biblioteca padrão, idempotente, e volta a correr sempre que editares o dossiê. Guarda o HTML em docs/dossie.html e corre python3 tools/split_dossie.py docs/dossie.html docs/design.

```gdscript
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
    for m in re.finditer(r'<section id="(s\d+|trk)"[^>]*>(.*?)</section>', doc, re.S):
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
```

> **A regra que isto impõe**
>
> docs/design/ é gerado, nunca editado à mão — o cabeçalho de cada ficheiro di-lo, para o agente ler. A fonte única continua a ser este dossiê. Quando mudares uma regra de design, mudas aqui, voltas a correr o script, e o commit mostra exatamente que secções mudaram: o diff da spec passa a ser revisível como o do código.
