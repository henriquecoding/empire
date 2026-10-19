# ADR 0085 — O elenco V15 no jogo

Estado: aceite para implementação pelo pedido do autor de 19/10/2026.

O autor anexou `EMPIRE-ANIMACOES-64-80-V15(1).zip` e duas capturas da produção, mostrando que a pesquisa da PR #113 estava na main, mas o seletor e a partida continuavam com a arte anterior. Pediu implementar tudo o que foi criado e aprovado no chat de personagens.

## Decisão

Importar os arquivos entregues, sem gerar novas imagens, redesenhar, recortar automaticamente ou homogeneizar a frequência dos quadros. `tools/export_royals.py` conserva o atlas de cada personagem byte a byte, verifica os hashes RGBA declarados por quadro e preserva pivôs, espelhos, tags, durações e marcadores. As fontes Aseprite ficam em `art/source/royals_v15/`. O export verificável fica em `art/export/royals/` e entra nos três presets.

`OriginalArt` dá prioridade ao `RoyalArt` para os seis perfis das duplas iniciais. O seletor mostra as duplas animadas com filtro Nearest e ampliação inteira. `UnitArtBatch` usa os novos corpos, com o relógio e as regras de combate existentes. `RoyalMotion` conserva a duração das reações, recuperação, bloqueio, canto e entrega que a apresentação observa. Dano e projéteis continuam determinados pela simulação; os marcadores importados não executam efeitos de gameplay.

O combate adapta a timeline do golpe ao ritmo existente de `CombatFx`/`StrikePose`. A frequência e os intervalos relativos do arquivo ficam preservados na fonte e na galeria; o combate não passa a ter o cooldown da demonstração artística. Para os novos corpos não se aplica a deformação procedural do corpo antigo. As duas direções usam os frames e pivôs entregues, sem um segundo espelho no desenho.

A tela nativa e a caixa opaca são medidas diferentes: o Rei ocupa menos que toda a tela de 80 pixels. A arte anterior e os dados de vida, alcance, velocidade e preço não são fontes para redimensionar automaticamente a entrega.

## Sombra e Bailarina

A aparência do Sombra substitui o empréstimo do cavaleiro para o corpo `buried_knight`. A seleção inicial permanece com os três perfis de `monarchs.csv`: o pedido artístico não definiu o desbloqueio nem o serviço remunerado de um quarto par. A Bailarina não recebe stats inventados nem substitui o Bardo da Nia.

Todas as ações entregues ficam acessíveis na galeria **Animações do elenco**, aberta na seleção e na pausa. A sequência do Sombra é executada pelo Godot com `sit → heal → stand`, a Bailarina dança ao lado e as plantas crescem em camadas inteiras. Isso é integração da apresentação; não equivale a implementar a cura do Cavaleiro Enterrado ou um quarto monarca jogável.

`RoyalGarden` usa a agenda entregue e os desenhos de crescimento/murchamento de cada espécie. Cada ativação sorteia uma vez pelo fluxo `VISUAL` do `RngService`. Não há sorteio por frame, transformação vertical do campo pronto, divisão de caules nem rotação de plantas. A raiz de cada planta permanece na mesma posição. A agenda fixa continua disponível para testes.

## Validação

- Importação: pixels fonte, transparência binária, hashes, dimensões, pivôs, tags, durações e filtros de export.
- `royal_animation_test.gd`: escolha do export no runtime, limites dos atlas, espelhos/pivôs, tempos, reação/recuperação e estágios individuais de plantas.
- Suite completa, portões, vistoria e Web: registrar o resultado efetivo em CV-04; não deduzir teste no navegador da simples existência do ZIP.

A revisão artística continua sendo do autor. Não se afirma abertura dos editáveis no aplicativo Aseprite.
