# Jogar e testar no Windows

`JOGAR-E-TESTAR.bat`, na raiz, abre um menu que corre o jogo e os mesmos portões e instrumentos
que o `Makefile` e o CI — **sem `make`, sem WSL e sem Bash**. Duplo clique, e **2** para uma
partida nova.

Sem menu, aceita um comando — útil para atalhos e para outros scripts:

```powershell
JOGAR-E-TESTAR.bat ajuda        # a lista
JOGAR-E-TESTAR.bat novo         # partida nova
JOGAR-E-TESTAR.bat validar      # tudo o que o CI corre e cabe no Windows
JOGAR-E-TESTAR.bat vistoria 12  # doze dias vigiados
```

Os comandos de teste devolvem `0` quando nada falhou.

## O que é preciso

| Ferramenta | Para quê | Onde é procurada |
|---|---|---|
| Godot, o ZIP oficial de Windows | Tudo o que abre o motor | `GODOT`, depois `C:\Tools\Godot` (a versão de `.godot-version` primeiro; senão a mais nova que lá estiver), depois o `PATH` |
| Python 3 | Portões do dossiê, conteúdo, spec e afirmações; servir a build Web | `py -3`, depois `python` |
| `git` | Estado, portão da spec, atualizar | `PATH` |
| `gh` | Trazer as builds do CI | `PATH`, com `gh auth login` feito |
| `pillow`, `gdtoolkit` | Contar a silhueta; `gdformat` e `gdlint` | Instalam-se pela opção 20, nas versões de `tools/requirements.txt` |
| Templates de export | Exportar aqui | `%APPDATA%\Godot\export_templates\<versão>` (no editor: *Editor → Gerenciar Modelos de Exportação*) |
| Node, Playwright | Os dois portões da camada do dossiê | `node` no `PATH`; `ferramentas\node_modules\playwright` |

O que faltar **não chumba**: o passo aparece como `SALTADO`, com o motivo.

O menu usa sempre o `…_console.exe` do Godot — o `.exe` normal não escreve na consola, e é por
isso que um comando de teste lançado com ele parece não fazer nada.

> **Uma versão do Godot mais nova do que a fixada** serve para jogar e para correr os testes, mas
> no *editor* pode reescrever ficheiros do projeto (por exemplo `config/features` no
> `project.godot`). Não faças commit disso: o CI corre na versão de `.godot-version`. A opção 16
> mostra o que ficou alterado.

## O menu

| # | Opção | O equivalente |
|---|---|---|
| 1 | Continuar a partida | `godot --path .` |
| 2 | Partida nova | `godot --path . -- --novo` |
| 3 | Abrir no editor | `godot --path . -e` |
| J / F | Janela ↔ ecrã inteiro; FPS na consola | `--fullscreen`, `--print-fps` |
| 4 | Verificação rápida: import, arranque *boot → jogo*, dados, lint da simulação, RNG | `make importar dados rng` |
| 5 | Suite gdUnit4 | `make testes` |
| 6 | Validação completa: os jobs do CI que correm no Windows, com tabela e `resumo.txt` | `make tudo` + silhueta, export e dossiê |
| 7 | Vistoria de N dias | `make vistoria DIAS=N` |
| 8 | Cenário da noite | `scenes/tests/night_test.tscn` |
| 9 | Dez dias | `scenes/tests/dez_dias.tscn` |
| 10 | Fotografias do meio da manhã e do meio da noite, e a silhueta | `make captura captura-noite silhueta` |
| 11 | Abrir o último relatório do gdUnit4 | `reports/report_N/index.html` |
| 12 | Trazer `empire-windows-debug` e `empire-web` da corrida verde deste commit | artifacts do job `export` |
| 13 | Jogar a build de Windows (a exportada aqui ou a do CI, a mais recente) | — |
| 14 | Servir a build Web e abrir o browser | `python -m http.server` |
| 15 | Exportar aqui | `make exportar-windows exportar-web` |
| 16 | Estado: commit, ficheiros alterados, versões, templates, builds e saves | — |
| 17 | Abrir a pasta dos saves | — |
| 18 | Atualizar: `git pull --ff-only` e reimport (recusa com alterações locais) | `make importar` |
| 19 | Relatório de defeito com os campos do modelo do GitHub, já com commit, Godot, sistema, semente e erros do último jogo | `.github/ISSUE_TEMPLATE/defeito.yml` |
| 20 | Instalar `gdtoolkit` e `pillow` | `make ferramentas-python` |

Fora do menu ficam o `actionlint` (binário de Linux) e o export de Linux: o que eles provam só
vale onde correm, e o CI corre-os.

## Onde fica cada coisa

| O quê | Onde |
|---|---|
| Registo de cada ação, e o `resumo.txt` dos pacotes de teste | `build\logs\<data>_<ação>\` |
| Relatórios do gdUnit4 | `reports\report_N\index.html` |
| Fotografias (o PNG e a ficha `.json` que o `check_silhueta.py` lê) | `build\capturas\` |
| Builds | `build\windows\`, `build\web\`, `build\ci\` |
| Relatórios de defeito | `build\defeitos\` |
| Saves — três slots rotativos, gravados na alvorada a partir do dia 2 | `%APPDATA%\Godot\app_userdata\Empire\saves` |

O menu só escreve em `build\` e `reports\`, os dois no `.gitignore`, e põe um `.gdignore` em cada
um: o import do Godot varre o projeto inteiro, e sem isso as fotografias passavam a ser recursos
do jogo — e entravam no `.pck` de um export local, que o `exclude_filter` não apanha.

## As armadilhas do Windows, e o que o menu faz

- **Os testes correm com os saves postos de lado.** A suite grava e apaga slots em `user://saves`,
  que é a mesma pasta das partidas de quem joga. O menu move a pasta antes e repõe-na no fim; se a
  janela fechar a meio, repõe-na na vez seguinte. Não jogues enquanto os testes correm.
- **O portão da spec compara conteúdo, não bytes.** No Windows o `split_dossie.py` escreve CRLF, e
  o `git status` passa a dar `docs/design` inteiro como alterado sem uma letra mudar. O menu usa o
  diff normalizado do git e repõe os ficheiros que a ferramenta reescreveu.
- **Erros que não são falhas.** No primeiro import: `Cannot open file '…translation'` — o motor
  gera-os logo a seguir, e é por isso que o `make importar` acaba em `|| true`. Na suite:
  `ERROR: save: …` — há testes que atacam o save de propósito (ADR 0007).

## Testar o save à mão

Uma partida sem ninguém a defender pode cair antes do primeiro autosave, e então não há nada para
retomar. Para o provar a sério:

1. **2** (partida nova); recruta, constrói, e sobrevive à primeira noite.
2. Na alvorada do dia 2 o jogo grava — o resumo no fim da sessão lista o `slot_N.save` com a hora.
3. Fecha a janela e escolhe **1**: a semente do resumo tem de ser a mesma.

## Controlos

| Ação | Teclado e rato | Comando |
|---|---|---|
| Andar | `A`/`D` ou setas | Analógico esquerdo, D-pad |
| Largar moeda (uma por toque) | `Espaço` | A |
| Passagem (Verbo 2) | `E` | X |
| Painel de estado — semente, tick, FSM | `Tab` | Y |
| Marcar alvo | Botão direito | Gatilho direito |
| Câmara livre | `Q` / `Z` | Analógico direito |
| Pausa | `Esc` | Start |

## Se alguma coisa correr mal

- **"Não encontrei o Godot"**: põe o executável em `C:\Tools\Godot`, ou aponta a variável `GODOT`.
- **A janela fecha sozinha**: abre uma consola na pasta do projeto e corre lá o `JOGAR-E-TESTAR.bat`,
  que o erro fica à vista.
- **O jogo não abriu**: o registo do motor está em `build\logs\<data>_jogar\jogo.log`.
- **Fechaste uma corrida de testes a meio**: os saves estão em
  `%APPDATA%\Godot\app_userdata\Empire\saves_guardados_durante_os_testes` e voltam sozinhos da
  próxima vez que abrires o menu.
