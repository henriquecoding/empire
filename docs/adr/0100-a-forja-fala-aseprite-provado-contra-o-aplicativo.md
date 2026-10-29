# ADR 0100 — A Forja fala Aseprite, provado contra o aplicativo

- Estado: aceite
- Data: 2026-10-29
- Secção do dossiê: §22 e §28 (os slots e a fonte em Aseprite)
- Complementa: ADR 0088 (a Forja), 0098 (cenários); a Asset Bible §2, §3 e §5 e o `tools/export_aseprite.sh` não mudam
- Tarefa: [FORJA-14](../backlog/FORJA-14.md)
- Origem: o pedido do dono de 29/10, *«total compatibilidade ao aseprite […] compatível com camadas e animações bem
  searadas e definidas»*; [pesquisa e prova](../art/research/2026-10-29-forja-aseprite/README.md)

## Contexto

A fonte de toda a arte do Empire é o `.aseprite` (§28): uma camada por slot, uma tag por animação, uma folha por
camada. A Forja escrevia-o pela especificação pública com uma camada RGBA, relia-o com o leitor do projeto e dizia que
abrir no aplicativo continuava por registar; o `tools/export_aseprite.sh` nunca tinha corrido. Um escritor e um leitor
nossos podiam partilhar o mesmo erro, e a especificação cala o que o aplicativo faz: como compõe os grupos, de onde vem
a cor de uma tag, a ordem das slices, o que o `--layer` torna visível, o que vai no JSON.

## Decisão

1. **O formato inteiro, numa só implementação.** `tools/forja/ase/` lê e escreve o `.aseprite` 1.3 completo (todos os
   chunks da especificação de 1.3.18.6 menos os de máscara e caminho, obsoletos), na ordem do encoder do aplicativo e
   com bytes determinísticos. A composição e as 19 misturas portam-se do código **MIT** do Aseprite (`src/doc`,
   `src/render`), com a aritmética de 8 bits dele, e a leitura e a escrita seguem o `src/dio`, também MIT (o aviso
   está no `NOTICE.md`); o que é do aplicativo (`src/app`, EULA) **não se porta**: o JSON da CLI e o `--layer`
   reproduzem-se pela saída observada.
2. **A prova é o aplicativo.** O Aseprite compila-se do código da versão e corre em batch sobre sprites que ele próprio
   fez, sobre os que a Forja escreve e sobre as fontes do dono: a Forja tem de ver o que o Lua dele vê, renderizar o
   que ele exporta, escrever o que ele abre e regrava sem perder nada, e exportar a folha, o JSON e o resultado do
   script como ele. O binário é só da prova: não se versiona, não se distribui, não é dependência.
3. **O CI repete a prova sem o aplicativo.** Os ficheiros que o Aseprite produziu ficam em
   `tools/forja/tests/ase_fixtures/` (fora do LFS) e os testes conferem-nos. Mudar o leitor, o escritor, a composição ou
   a exportação de forma que deixe de bater com o aplicativo chumba o CI.
4. **As convenções do Empire são código.** Os slots e variantes (§2–§3), a ordem Z da §58, as camadas de trabalho, as
   tags do ANIMATION_BIBLE e o pivot conferem-se (`forja ase`, `forja.ase_check/1`); só o que a exportação por camada
   não consegue separar (dois nomes iguais) e uma tela fora do contrato são erro, o resto informa o autor. A Forja
   monta um corpo com uma camada por slot (`forja aseprite --slot`), o terreno Wang em tilemap e a construção com os
   estados em tags e o contrato em slices.
5. **O contrato de cena não se reescreve pelo ficheiro.** Os vãos, sinais e zonas vão para slices; lidos de volta,
   dizem o desvio (`forja ase --scene`) e quem decide é o contrato.

## Alternativas consideradas

- **Uma biblioteca de terceiros** para ler e escrever: seria dependência nova (regra 8) e teria de passar pela mesma
  prova; a composição e o JSON da CLI continuariam por fazer. Não se fez o levantamento das que existem.
- **Chamar a CLI do Aseprite em vez de a reproduzir.** Prenderia a Forja a um binário com licença comercial que o CI e
  quem gera arte não têm; continua a ser a prova, não o caminho.
- **Portar o `src/app` para o JSON.** É código sob EULA; a saída observada chega e confere-se.

## Consequências

- Módulos novos: `tools/forja/ase/` (`model`, `binio`, `read`, `write`, `blend`, `render`, `build`, `describe`,
  `export`, `empire`, `cena`) e `cmd_ase.py`. Comandos novos: `ase` (só lê) e `exportar`; `aseprite` ganha `--slot`,
  `--reference` e `--kind` e passa para `cmd_ase`; `tileset` e `estrutura` ganham `--aseprite`. Também por MCP.
- **Muda de comportamento:** o `.aseprite` das entregas (`sheet`, `anim`, `forge --aseprite`) passa a ter os bytes do
  encoder do Aseprite (as tags com chunk de dados, a camada com o slot nos dados, uma tag sem ciclo com repetição 1,
  as cels repetidas ligadas); o `verify` lê-o com o leitor exato. O `tools/aseprite_source.py` continua para o
  `export_originals.py`.
- O `tools/export_aseprite.sh` passou a ter prova (igual à Forja no `troop.aseprite`); que o pivot não chegue ao JSON é
  a Q-302.
- Aprovar continua a ser do dono (ADR 0093); a importação no Godot continua na ADR 0010.
