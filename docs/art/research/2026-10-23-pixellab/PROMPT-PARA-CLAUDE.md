# Instrução de continuidade para Claude

Use este texto junto com `AUDITORIA-FORJA-CLAUDE.md`, `RELATORIO-MESTRE.md` e toda a pasta
`docs/art/research/2026-10-23-pixellab/` do repositório `henriquecoding/empire`.

---

Quero construir uma ferramenta independente de geração e produção de pixel art
com qualidade comparável ao PixelLab nas necessidades do meu jogo Empire.
O relatório anexo contém uma pesquisa pública extensa e uma proposta técnica.
Transforme esse material em trabalho executado, com resultados verificáveis.

A Forja já existe em `tools/forja/`, integrada no PR #117. Continue essa
implementação: não refaça contratos, exportadores e CLI em uma ferramenta
paralela. A auditoria avalia o commit `68ed1c87461f5d39dd21fb664eef2930ddeaac81`;
compare com a `main` atual para não repetir correções já realizadas.

Leia primeiro `AGENTS.md`, `docs/art/CHARACTER_PRODUCTION_GUIDE.md`,
`PIXEL_ART_STUDY_GUIDE.md`, `ASEPRITE_WORKFLOW.md`, `REFERENCE_AUTHORITY.md`
e `docs/art/FORJA.md`, a ADR 0088, a auditoria e o relatório mestre.
Consulte as decisões atuais antes de usar uma referência.
O relatório tem uma data de corte; não presuma que todos os contratos externos
continuam iguais.

## Objetivo visual

- Estudos em canvas nativo de 64×64 e 80×80, com ocupação útil adequada ao corpo
  e à ação. Canvas, área opaca, cabeça e escala no mundo são medidas distintas.
- Personagens expressivos e cômicos, rosto legível, silhueta forte e equipamento
  reconhecível, sem blur de reamostragem.
- Identidade consistente entre poses e frames, com braços, mãos e objetos
  mantendo continuidade. Não completar contagem de frames com duplicações
  escondidas.
- Movimento por poses, apoios e timing. Para as flores da Sombra, crescimento
  individual em estágios; simples rotação de uma imagem não atende ao objetivo.
- Exportação rastreável e integração compatível com os contratos do Empire.

## Primeiro ciclo de implementação

1. Reproduza F01–F09 com `reproduce_forja_findings.py`, inspecione a saída e
   registre uma tarefa de reparo. As sondas descrevem bugs; novos testes devem
   afirmar o comportamento corrigido, não congelar o erro como expectativa.
2. Corrija primeiro F01/F02/F03/F09: submissão sem retry ambíguo, tamanhos e
   referências por backend, guias realmente transmitidas e jobs com prazo,
   cancelamento e retomada. Faça esses testes sem chamadas pagas.
3. Corrija F04/F05/F06/F08: preservar azul e transparência na edição, permitir
   detalhes de um pixel, manter deslocamentos intencionais e direção das tags.
   Não alterar poses existentes, contratos de runtime ou assets aprovados.
4. Resolva F07 separando validade estrutural, revisão de movimento e aprovação
   artística. Corrija alegações de qualidade não demonstradas na documentação.
5. Complete uma fatia vertical existente: referência autorizada → planejamento
   validado → geração real → revisão → exportação → round-trip. Use `royal_64`
   e `royal_80` para estes estudos, sem substituir contratos globais. Para
   independência, introduza depois um backend licenciado e substituível.
6. Execute o piloto do plano com teto de custo e referências definidos antes
   do gasto. Se inferência não estiver disponível, conclua os reparos locais,
   registre a dependência exata e não invente resultados. Preserve todas as
   saídas e meça retrabalho humano. Só então avance para referência/pose,
   ajuste de estilo e clips curtos.
   Treino nativo é uma hipótese de melhoria, não um requisito para a primeira
   versão utilizável.

## Disciplina técnica

- Separe fatos documentados, inferências e escolhas próprias. Não descreva a
  arquitetura proposta como arquitetura interna recuperada do PixelLab.
- Não assuma que Pixflux é FLUX, que os modelos atuais são todos SDXL ou que
  um repositório de SDK/MCP contém os pesos do serviço.
- Não use outputs PixelLab para treinar ou destilar sem autorização aplicável.
  Mantenha permissão de treinamento por fonte e split por família/personagem.
- Fixe pesos, licenças, versões, configuração, referências e hashes. Registre
  se a arte foi gerada nativamente, reduzida de alta resolução ou corrigida.
- Evite combinar adaptadores, módulos temporais e backbones incompatíveis.
- Não trate a instalação de um pacote como prova de que suporta a API atual.
- Não faça retry cego de POST cobrado após timeout. Persista e reconcilie jobs.
- Preserve regiões e frames congelados com comparação exata do raster final.
- Não confunda variantes, direções e frames temporais; confira ordem e timing.
- Não altere a simulação a partir de eventos de arte. Use os adaptadores e
  exportadores existentes, respeitando pivots, origens, aliases e espelhos.
- Siga as regras locais de dependências, ADR, testes, scripts e revisão de PR.

## Prova de qualidade exigida

Entregue arquivos reais, comandos executados, saídas completas do piloto,
comparações em 1×/2× e movimento, métricas de contrato, custos conhecidos,
tempo humano e falhas abertas. Separe design aceito, animação revisada e
integração testada. Um score automático não aprova a direção de arte.

Não declare “igual ao PixelLab” sem benchmark comparável. Uma interface com
imagens de demonstração, um wrapper de API ou um treino que apenas iniciou
não equivalem ao sistema completo. Termine cada ciclo com uma capacidade
funcionando e um próximo experimento definido pelas falhas observadas.

## Resultado esperado do primeiro ciclo

Uma Forja corrigida e utilizável para um personagem, testes de regressão e integridade,
exportação reproduzível, resultado de piloto honesto e um plano atualizado
para melhorar identidade e animação. Mantenha a documentação e a implementação
no repositório e conclua o processo de PR/CI conforme `AGENTS.md`.
