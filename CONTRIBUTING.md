# Contribuir

O contrato está em **[AGENTS.md](AGENTS.md)** e vale para pessoas e para
agentes. Este ficheiro é só a mecânica: como pôr isto a correr, e que comandos
o CI vai correr contra o teu diff.

## Pôr a correr

Precisas do Godot fixado em [`.godot-version`](.godot-version) no `PATH` como
`godot` (ou em `GODOT`), do Python 3.11+ e do Node 22 para a camada do dossiê.

```bash
make ferramentas-python     # gdtoolkit, na versão fixada em tools/requirements.txt
make importar               # obrigatório num checkout frio (§69)
make hooks                  # liga o pre-commit que corre os portões estáticos
make tudo                   # portões + dados + a suite inteira
```

`make ajuda` lista tudo. Os alvos são exactamente os passos do CI — o workflow
chama-os, não os repete. Um portão que corre de forma diferente na tua máquina e
no *runner* é um portão que só chumba onde não estás a olhar.

## O ciclo

Uma tarefa, uma sessão, um *merge* (§29). O ticket é a unidade.

1. Abre `docs/backlog/<id>.md` e lê as secções de `docs/design/` que ele cita.
2. Escreve ou actualiza o teste em `tests/`. **Confirma que falha.**
3. Implementa o mínimo que o faz passar.
4. `make tudo`.
5. Só com tudo verde, abre a PR com a checklist preenchida.
6. Muda o **Estado** no ficheiro do ticket e na tabela de `docs/backlog/README.md`,
   no mesmo *commit*.

## Os portões, e o que cada um defende

| `make` | O quê | Porquê chumba |
|---|---|---|
| `formato` | `gdformat --check` | O formato não se discute em revisão |
| `estilo` | `gdlint` | Inclui o limite de **250 linhas** por ficheiro (§28) |
| `rng` | G2 (§40 I2) | `randi`/`randf` fora do `RngService` quebra a promessa da semente |
| `dossie-numeros` | 193 valores | Um número do dossiê que os CSV desmentem |
| `conteudo` | `content_report --check` | SCHEMA, PROPOSALS, ROT_BY_DAY e NAMES desactualizados |
| `spec` | `docs/design/` | É **gerado** do dossiê; editar à mão perde-se na geração seguinte |
| `afirmacoes` | `check_claims` | Um número escrito à mão que a contagem desmente |
| `dados` | ADR 0004/0008 | Um `.tres` editado à mão, ou a ferramenta por correr |
| `testes` | gdUnit4 | G1, G3, G4, G5 e os catorze testes de design |
| `exportar` | O binário | Prova que isto é um jogo e não uma pasta |

## O que não se edita à mão

Três árvores são **geradas**. Editá-las directamente é perder a edição na
geração seguinte, em silêncio — e o CI apanha-o, mas depois de já teres
escrito:

| Gerado | A fonte | Regenera com |
|---|---|---|
| `docs/design/**` | `docs/dossie.html` | `make spec` |
| `data/**/*.tres` | `data/source/*.csv` | `make dados-gerar` |
| `docs/content/{SCHEMA,PROPOSALS,ROT_BY_DAY,NAMES}.md` | os CSV | `python3 tools/content_report.py` |

E uma regra que não tem ferramenta óbvia mas tem portão: **não escrevas à mão um
número que uma ferramenta conta.** O README, o `RETOMADA.md` e o
`validation.json` são reconferidos a cada *push* por `tools/check_claims.py`.
Se acrescentaste uma tabela, corre `make afirmacoes-escrever` e actualiza a
prosa — não ajustes o número à mão e sigas em frente.

## Arte e áudio

`art/source/` e `audio/` estão em **Git LFS** desde o primeiro commit. Instala o
`git-lfs` antes de lhes tocares, ou vais commitar ponteiros partidos:

```bash
git lfs install
```

`art/export/` é produzido pelo Aseprite Wizard e **não** se versiona — excepto
`art/export/_placeholder/`, que fica fora do LFS de propósito para que o CI, que
faz *checkout* sem LFS, continue a ter imagens reais no `boot.tscn`.

Asset em falta: *placeholder* de cor lisa em `art/export/_placeholder/` e uma
linha em `docs/ASSETS_TODO.md`. Não bloqueies uma tarefa de código por arte.

## Dúvidas de design

Não decidas. Escreve a pergunta em [`docs/QUESTIONS.md`](docs/QUESTIONS.md),
implementa a opção mais simples e mais reversível, e diz qual foi. Se a pergunta
fechar, a decisão vira **ADR** em `docs/adr/` *antes* de virar código ou dados.

Um teste de design a falhar é informação, não um obstáculo: não mudes um número
em `data/` para o calar.

## Commits e ramos

- Ramos: `<id-do-ticket>/<descricao-curta>` — por exemplo `f0-07/event-bus`.
- Um ticket por PR. O campo **O que este PR NÃO faz** do template não é
  decoração: é o que impede três tarefas no mesmo diff.
- Mensagens no imperativo, em português, e a dizer *porquê* — o *quê* já está no
  diff.

## Segurança

Falhas exploráveis não vão para issues públicas. Ver [SECURITY.md](SECURITY.md)
— e, se mexeres em saves, lê a [ADR 0007](docs/adr/0007-save-security.md)
primeiro. Um `load()` num caminho de save é execução remota de código.
