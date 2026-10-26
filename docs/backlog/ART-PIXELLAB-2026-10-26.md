# ART-PIXELLAB-2026-10-26 — engenharia reversa do PixelLab: método, contrato, forense e conferência

Estado feito — método pesquisado, achados novos com nível de evidência, Forja conforme o contrato de 26/10, grade
sem destruir sprites nativos, envio de 26/10 conferido; sondas pagas planeadas e por executar (sem chave nem teto)

## Pedido

O dono, a 26/10/2026: *«Quero que se aprofunde intensamente pela web sobre como fazer engenharia reversa e refine
tudo o que já foi feito para a engenharia reversa de https://www.pixellab.ai — não faça algo rápido ou sobre uma
coisa específica, quero que faça um trabalho completo»*; e, a meio: *«Hoje também enviei mais uma que está no último
deploy da Vercel, verifica ela também»* (o ramo do PR #123, FORJA-04).

## Spec e autoridade

[Pesquisa de 23/10](../art/research/2026-10-23-pixellab/README.md), [guia da Forja](../art/FORJA.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md),
AGENTS.md (regras 8 e 9: sem dependências novas, sem escrever em `art/`).

## Entrega

[Pacote de 26/10](../art/research/2026-10-26-pixellab-engenharia-reversa/README.md):

- Metodologia de engenharia reversa de um serviço de IA, com a lei (UE, Portugal, Suécia, EUA), os termos do
  PixelLab, a escada de evidência e o catálogo de técnicas, cada uma com o que se fez e porquê.
- Dossiê com a matriz de hipóteses H01–H15, a pilha e a infraestrutura por fontes passivas, os SDKs, a forense
  das imagens da documentação, a conferência do envio de 26/10 e a errata da pesquisa anterior.
- Scripts reproduzíveis (coleta, contrato, inferência das ferramentas Pro, forense, conferência, verificador) e
  os JSON que gravam.
- Forja: o adaptador PixelLab com limites por eixo, intervalos numéricos e o hash novo (10 divergências → 0); a
  força 0 da imagem inicial recusada antes da rede; `gridcheck.py` mede as ampliações exatas e recusa um período
  que a amostragem desmente.

## Limites

Sem chave, sem chamadas pagas, sem rotas privadas, sem automatizar a interface web, sem treinar nem destilar nada
com saídas do PixelLab (termos 1.2 e 2.2). As imagens de terceiros não entram no repositório. O limiar de pureza da
grade (0,8) está calibrado em imagens falsas e em três reais, não num conjunto de geradores. Nenhuma aprovação
artística; nada em `art/`, `src/`, `scenes/` ou `data/`.

## Verificação

`python3 -I docs/art/research/2026-10-26-pixellab-engenharia-reversa/verificar.py`, `make forja`, o verificador da
pesquisa de 23/10, `afirmacoes` e o CI do PR.
