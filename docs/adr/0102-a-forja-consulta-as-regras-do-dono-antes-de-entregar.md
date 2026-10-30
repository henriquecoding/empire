# ADR 0102 — A Forja consulta as regras do dono antes de entregar

- Estado: aceite, a pedido do dono
- Data: 2026-10-30
- Tarefa: [FORJA-16](../backlog/FORJA-16.md)
- Complementa: ADR 0093, 0094, 0096, 0097, 0099 e 0101
- Origem: Henrique voltou a rejeitar mãos, contornos com pixels duplos, expressões, forma/pega da poção e
  resolução aparente. Pediu: «coloque regras na forja para que sejam consultadas antes de entregar as coisas»
  e merge na `main`.

## Problema

Os guias já continham decisões, mas não havia uma consulta versionada comum aos agentes, pedidos e entrega.
O processo voltou a reduzir fontes detalhadas e a usar candidatos defeituosos como guias. Dimensões corretas,
contagens de dentes e contacto entre pixels foram tratados como evidência de acabamento que não demonstravam.

## Decisão

1. **Uma fonte declarativa e uma entrada humana.** `tools/forja/owner_rules.json` conserva regras, origem,
   leitura obrigatória, rejeições nativas e verificações. `docs/art/OWNER_RULES.md`, AGENTS e os guias mandam
   consultá-las antes de produzir e antes de entregar. `forja regras` e MCP `forja_regras` expõem a mesma fonte.
2. **A consulta acompanha o pedido.** Prompts ampliados e nativos recebem as regras aplicáveis; o `expect`
   conserva a revisão (hash do JSON e dos documentos), personagem e hash do recorte escolhido. Um plano
   desatualizado ou um prompt substituído sem as regras é recusado antes de construir o pedido ao fornecedor.
   Um candidato rejeitado não entra como guia de densidade/estilo, mesmo ao lado do conceito certo.
3. **A origem acompanha os pixels.** O forge recebe a consulta pelo `--expect`; a cadeia conserva-a nas
   reexportações e no patch. Uma consulta nova não reescreve a origem de uma cadeia existente. Uma etapa
   `deliberately_reduced` fica diagnóstica até ao fim, mesmo quando a última entrada já tem 64/80 pixels.
4. **Revisão obrigatória da imagem exata.** `forja visual` cria a ficha `forja.owner_review/1` pendente.
   Exige observador, data, método, conceito exato, vistas 1×/inteira/claro/escuro/lado a lado e oito aspetos
   com evidência e caixas: autoridade, grade, proporções, contorno, mãos/pega, rosto, forma do equipamento e
   materiais. Falha bloqueia; ausência ou incerteza continua pendente. Mudar imagem ou regras invalida a ficha.
5. **Um portão de apresentação.** `forja entrega PASTA`/`forja_entrega` exige o elenco completo e retorna
   `ok: false`/código CLI 1 quando faltar candidato ou revisão. `--character` declara explicitamente um piloto.
   `ready_for_review` exige também runtime, sinais, identidade e cadeia resolvidos. `release_ready` exige a
   aprovação separada do mestre pelo dono; uma revisão do agente não a concede.

## Evidência e limites

Os testes reproduzem falta de consulta/revisão, prompt trocado, guia rejeitado, redução herdada, imagem alterada,
conceito errado, regras desatualizadas e elenco incompleto. A revisão só lê pixels: não engrossa bordas nem apaga
detalhes. O orçamento nativo mede tela e área ocupada sem impor uma percentagem arbitrária de preenchimento.

A ficha regista evidência declarada por quem realmente olha; não é um avaliador automático de qualidade artística
nem uma barreira contra metadados deliberadamente falsificados. Não preenche verificações positivas, não aprova
sprites e não prova que uma pessoa leu os documentos. O comando cru `generate` continua diagnóstico: não cria
por si a consulta ligada à autoridade necessária para passar a entrega.

Sem dependências novas. A decisão altera o protocolo de produção e entrega, não o algoritmo de rasterização.
