# ART-ANIMATIONS-2026-10-18 — oito personagens animados

Estado: pacote V12 produzido; aguardando revisão visual do autor.

Henrique apreciou parcialmente a V11, apontou pixels ainda melhoráveis e pediu animar todos os personagens e receber um ZIP. O pedido seguinte foi continuar. A V11 é a base desta etapa; a V9 rejeitada não foi reutilizada.

Entrega: [animações V12](../art/animations/2026-10-18-imperadores-v12/README.md). Todos os corpos completos mantêm células 64×64 ou 80×80. O pacote reúne PNGs transparentes por ação, atlas, Aseprite com camadas e tags, JSON de quadros/durações/pivôs, prévias GIF/MP4 e visualizador HTML local.

As poses incluem repouso, caminhada, corrida, impacto, queda recuperável, levantar e ações das formas iniciais. Rei usa espada, Nia machadinhas, Escudeiro escudo, Bardo alaúde, Arqueiro arco, Intendente flechas; Sombra senta/cura/levanta e Dançarina dança. Flores são efeito separado. Rostos mantêm a forma durante os ciclos; pálpebras fechadas são estados próprios, e Sombra conserva elmo fechado.

Referências consultadas: ANIMATION_BIBLE, EXPRESSION_GUIDE, ASSET_BIBLE, seção 08 de design e pesquisa arquivada. A especificação 64/80 do autor prevalece sobre antigas propostas de 128. Não foram inventados ataques para a forma inicial do Sombra nem equipamentos de evoluções.

Verificação: leitor independente compara cada quadro PNG/atlas/Aseprite, durações, tags, pivôs, alfa binário e espelhamento. Relatório gerado em verificacao.json. Sequências inspecionadas visualmente em ampliação inteira. Aseprite e Godot não estavam disponíveis para abrir/importar os arquivos; não há teste em runtime nem aprovação artística presumida.

Escopo de repositório: fontes reproduzíveis e documentos em docs/. Nenhuma mudança em art/, audio/, src/, scenes/ ou data/. A suite do jogo não é um gate pertinente a esta entrega documental de assets. O PR de revisão permanece em rascunho.
