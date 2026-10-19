# Pesquisa consolidada — personagens e animação

Conhecimento reunido em 19/10/2026 a pedido de Henrique para permanecer utilizável no repositório. Inclui a pesquisa de imperadores/escudeiros, sprites compactos/PixelLab, diagnóstico da V12/V13, revisão de Sombra/bailarina e floração da V15.

## Aplicar no próximo trabalho

- [Guia de produção](../../CHARACTER_PRODUCTION_GUIDE.md): design, escala, luz, materiais, expressão, geração controlada e ficha de personagem.
- [Animação por poses](../../CHARACTER_ANIMATION_WORKFLOW.md): apoio, timing, continuidade, equipamento, pivôs e exportação.
- [Floração individual](../../ORGANIC_FLOWER_ANIMATION.md): estágios, raiz, agenda por planta e adaptação ao Empire.
- [Checklist de revisão](../../CHARACTER_REVIEW_CHECKLIST.md): design, movimento, arquivos e integração separados.
- [Decisões e estado](DECISOES-E-ESTADO.md): o que foi rejeitado, aceito e ainda precisa de revisão.
- [Fontes e aplicação](FONTES-E-APLICACAO.md): fontes primárias, uso prático e limites da consulta.

## Pesquisa preservada

| Material | Conteúdo e estado |
|---|---|
| [Arquivo de 18/10](../2026-10-18-imperadores-escudeiros/README.md) | Pesquisa aplicada por capítulos, estrutura/luz/sombra, expressões, referências, estudos e ZIPs originais |
| [Sprites compactos e PixelLab](../2026-10-18-imperadores-escudeiros/PIXEL-ART-COMPACTA-E-PIXELLAB.md) | Adaptação de referências, autoria nativa, escala e recursos documentados da ferramenta |
| [Diagnóstico e pesquisa V13](historico/PESQUISA-E-CORRECOES-V13.md) | Falhas da V12, poses completas, braços, alaúde, arco e limites da conferência técnica |
| [Pesquisa e proposta de Sombra](historico/PESQUISA-E-PROPOSTA-SOMBRA.md) | Pesquisa profunda, comparação de caminhos, nova dupla e plantas individuais |
| [Prancha de design aceita](referencias/sombra-bailarina-design-aceito.png) | Referência aceita para continuar; não é animação nem raster nativo de produção |
| [LEIA-ME original V15](evidencias/v15/LEIA-ME-ORIGINAL.md) | Descrição histórica do pacote e suas limitações |
| [Prompts integrais V15](evidencias/v15/prompts.json) | Ferramenta real e pedidos das folhas; pedido não equivale a resultado comprovado |
| [Extração](evidencias/v15/extracao.json) e [paletas](evidencias/v15/paletas.json) | Medidas, contagens reais e rampas usadas nos estudos |
| [Manifesto](evidencias/v15/manifest.json) e [verificação](evidencias/v15/verificacao.json) | Inventário e testemunho técnico do pacote, não do runtime do repositório |
| [Jardim padrão](evidencias/v15/jardim-padrao.json) e [relógio CJS](evidencias/v15/jardim.cjs) | Agenda reproduzível do demonstrador, sem dependências externas |
| [Procedência e hashes](PROVENIENCIA.json) | Arquivos de origem, hashes, ferramenta, escopo e limites de execução |

Os documentos em `historico/` e o LEIA-ME V15 foram preservados integralmente. Suas frases de próxima etapa e instruções de copiar scripts descrevem aquela entrega. Usar o [estado atualizado](DECISOES-E-ESTADO.md) e a [adaptação ao Empire](../../ORGANIC_FLOWER_ANIMATION.md#adaptar-ao-empire): o protótipo Godot do ZIP não cumpre ainda o contrato de RNG/tipos do projeto.

Os sprites, atlas e prévias completos continuam no pacote `EMPIRE-ANIMACOES-64-80-V15.zip` entregue na conversa. A cópia dos manifestos nesta pasta não instala os assets citados nem promove a animação a arte aprovada do jogo.

## Provas e limites

O relatório V15 preserva o resultado de comparação entre PNG, Aseprite e JSON, tempos/pivôs/espelhos e reconstrução independente do jardim. É testemunho da verificação do pacote original. Aqui a integridade das cópias é conferida por hashes; não se afirma que o verificador completo possa ser reexecutado sem os sprites do ZIP.

O relógio CJS pode ser reproduzido isoladamente:

```sh
node -e 'const g=require("./docs/art/research/2026-10-19-character-animation/evidencias/v15/jardim.cjs"); console.log(JSON.stringify(g.createGarden(20261019), null, 2));'
```

Seu RNG próprio existe apenas para reconstruir o experimento histórico offline. O runtime continua usando RngService. O fluxo de leitura está no AGENTS.md e nas bíblias, para orientar a próxima produção.
