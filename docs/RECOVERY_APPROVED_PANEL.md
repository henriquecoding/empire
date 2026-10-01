# Retoma das onze respostas aprovadas — 01/10/2026

Branch de trabalho: `codex/approved-panel-remaining`. Os checkpoints são trabalho
em curso; não significam integração em main nem respostas aplicadas no painel.

A primeira cópia local perdeu-se quando o ambiente foi restaurado. As aprovações,
o histórico da conversa e a main ficaram intactos. Reconstrução por checkpoints.

## Checkpoint 1

Regras puras de estações e reservas de grão; mercenários pagos abaixo do limiar
regular e exércitos estrangeiros excluídos da conta do rei; estado dos acampamentos;
alicerces que retêm nível, caminho e variante. Quinze testes focados passam.
Os valores novos estão em `rules.csv` e marcados como propostas ajustáveis.

## Trabalho ainda necessário

- Q-170: ligar fecho dos acampamentos a muralhas/cortes; casa de cidadãos.
- Q-171: ligar legado aos alicerces; repor estruturas dinâmicas por tipo/posição.
- Q-172: HUD das quatro estações e guia das alternativas de inverno.
- Q-174: ecossistemas autónomos, tesouro, obras, população, tropas e noite locais.
- Q-175: kits dos oito povos; Bruma como nome de trabalho; migrar Paul nos saves.
- Q-176: tesouro/guarda/relíquia, prémios duplos/triplos, persistência sem reposição.
- Q-177: contador de três contratações e abandono físico do acampamento.
- Q-178: viagem rápida das classes a reinos conquistados seguros; rei permanece.
- Q-179: fissuras em um/dois lados conservando massa e curva inicial; limiar dia 12
  já existente em rot.csv, nunca antecipar para dia 6 (falha defesa dez noites).
- Q-180: mapa revelado e semente como legado, terras anteriores desabitadas.
- Q-182: janelas locais de dither, bocas visitadas e criaturas próximas.

## Regressões já identificadas na primeira tentativa

`WorldWorks.restore` deve tratar `AmargueiroSystem.CORTE` antes de consultar o
Registry; o id não é um BuildingData. Duas serras no mesmo x continuam a ser duas
obras distintas, por id. `AmargueiroSave.read` reutiliza a serra restaurada e repõe
as suas dimensões/custos a partir do protótipo do bosque, sem duplicar.

No legado, obras próprias dinâmicas (casas de cidadãos) devem ser repostas e os
ids remapeados por tipo e x antes de `Legacy.apply`, após restaurar o plano/mapa.
Owner 0 é SEM_DONO: testes de combate devem usar o dono real do rei.

## Conclusão obrigatória

Suite completa, portões, dados, vistoria, exportação e verificação de produção;
PR com CI verde antes do merge. Só depois actualizar exactamente as onze linhas
Q-170/171/172/174/175/176/177/178/179/180/182 para aplicada no Supabase, conservando
texto, escolha e restantes respostas. Nenhuma já marcada neste checkpoint.

## Checkpoint 2

Reconstruídas as ligações ao jogo de acampamentos/casas de cidadãos, alicerces e
mapa desabitado, kits dos oito povos e migração Bruma, reinos com tropas/obras e
caixa própria, masmorras variáveis persistentes, fissuras e segundo lado da noite,
viagens de classes e painel, estações no HUD, janelas locais do subsolo.

Testes focados de integração: sete passam, incluindo a viagem sem mover o rei,
reino autónomo e round-trip do tesouro, acampamento de mercenários abandonado,
guarda de masmorra que permanece à alvorada e não duplica ao carregar, duas serras
no mesmo x, casa de cidadãos em alicerce e mapa desabitado sem recrutas/tesouro.
Ainda faltam documentação final, suite completa, portões, verificação visual,
CI, merge e publicação. Nenhuma resposta foi marcada aplicada no Supabase.
