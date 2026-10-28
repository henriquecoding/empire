# Forja: produção séria de cenários e construções em pixel art

28/10/2026 · Revisão 2 · Empire · Base técnica inspecionada: `afbe0087dd4219752771c800a77e3786218257f8`.

## O resultado pedido

Ampliar o método dos personagens para arquitetura, vegetação, terreno e cenas remontáveis. O desenho precisa de ter identidade, volume, materiais, riqueza e intenção. O relatório de 32 páginas é a referência desta tarefa; os quatro PNGs são direções visuais geradas em revisão, não assets nativos aprovados. Este pacote não implementa o processo na Forja.

O piloto deve fechar uma oficina dos Enramados, uma árvore, um trecho de chão e os planos necessários à sua montagem. Primeiro demonstrar a qualidade desse conjunto; depois expandir as famílias. Um lint limpo não prova que a árvore tem anatomia, que o telhado tem espessura ou que a oficina conserva a sua identidade.

## Continuidade e restrições

Ler `AGENTS.md`, os contratos e a documentação artística da main antes de alterar. Conferir diferenças desde a base inspecionada e preservar os reparos dos personagens. O limite de 250 linhas por script continua aplicável. O inventário técnico anterior acompanha este pacote; não é uma nova auditoria de HEAD.

Preservar a janela 1280×720, superfície y=517 e referência inferior y=618,5. O espaço de uso vem de `UnderFit`, dos segmentos e das passagens reais. Tropas 64×64 e Rei 80×80 são réguas, não dimensões universais da arte. Usar os atores reais ao rever a montagem. Não arredondar posições da simulação para adaptar uma grelha artística.

Respeitar a composição efetiva: catálogo legado → `NativeSceneryCatalog.patch_legacy` → `OwnerScenery.patch`. Não somar as suas contagens como entregas independentes. Conservar a substituição de `mata_encharcada`, a transição `fenda_geada` e a ligação funcional de `OwnerSites.water`. Chão, obra e água funcional mantêm as suas âncoras no mundo; fundo distante usa o contrato de parallax.

## Autoridade visual como nos personagens

Registar cada referência com ficheiro, SHA-256, recorte, papel e estado. Distinguir:

- `visual_reference`: conceito/composição/material em discussão. Pode conter erros e não comprova uma grade nativa.
- `native_master`: desenho resolvido na resolução e convenção finais, revisto e aprovado na sua versão exata.
- `runtime_asset`: exportação desse mestre com origem, camadas, conectores e condições verificadas.

A aprovação não se herda de um conceito para uma conversão, isolamento, variante ou exportação. Separar identidade arquitetónica, composição, estilo, material, contexto de junção e régua de atores. Uma captura de Kingdom explica uma solução visual, mas não define o telhado do Empire.

Nas referências desta revisão, a oficina isolada reorganizou detalhes e contém alfa parcial. Não é uma extração exata do panorama. Todos os quatro estudos continuam com aprovação pendente. Não os substituir por versões reduzidas e declarar o resultado nativo sem revisão do desenho.

## Etapas de arte que a ferramenta deve suportar

1. **Brief:** bioma, função, habitantes, materiais locais e história de uso. Definir projeção lateral e o que pode mostrar espessura.
2. **Composição:** massas dominantes, vazios, ritmo, percurso, marco e luz. Rever janelas deslocadas da câmera.
3. **Estrutura:** anatomia da árvore, geologia, apoios, vãos, inclinação, espessura do beiral e contacto com o chão.
4. **Gramática:** exemplos de folha, tábua, junta, telha, face de pedra e terra. Dar a cada material formas e distribuição próprias.
5. **Mestre nativo:** resolver a forma na grade final por camada/objeto. Conservar os sinais distintivos, em vez de tentar preservar toda a textura pictórica.
6. **Separação:** exportar objeto, fundo, primeiro plano e efeitos; reconstruir e rever áreas antes ocultas. Pixels não vistos precisam de desenho novo, não de uma alegação de recuperação exata.
7. **Biblioteca:** produzir variantes, estados e módulos conservando origem e identidade.
8. **Montagem:** confrontar atores, obra, passagem, dia/noite e câmera móvel.
9. **Encerramento:** guardar o resultado exato, comparação, hashes e estado de aprovação.

Os recortes das páginas 7 e 11 do estudo tratam da organização das formas e materiais. Não transformar limpeza de clusters em proibição absoluta de pixels isolados: uma ponta de ferramenta pode precisar deles. Os limites de cores e contorno devem servir a família e o plano, não apagar indiscriminadamente materiais ou profundidade.

## Primeiras mudanças na Forja

Separar pedido, contrato, geração e revisão por responsabilidade. Nomes de módulos são sugestões; verificar os existentes antes de criar.

| Área | Mudança necessária | Prova concreta |
|---|---|---|
| `prompts.geometry`, `plan.py` | Dimensão explícita por tipo; retirar fallback 64×64 quando não semântico | Oficina, árvore e panorama têm extensões resolvidas antes da rede |
| `prompts.py`, `constraints.py` | Vocabulário arquitetónico e papéis de referência | Telhado/porta/chaminé não tratados como rosto/roupa/pose |
| Vista | Separar projeção do mundo e orientação do ator | Fachada lateral válida sem aceitar top-down indevido |
| Fundo e `pipeline.finish` | Céu opaco, terreno e bordas intencionais | Cleanup não remove chão/céu nem fecha vãos |
| Adaptador | Escolha de operação por capacidades atuais | Plano não promete dimensão ou referências que a rota não envia |
| Fidelidade | Máscara interna e preservação até à exportação | RGBA protegido idêntico no PNG final |
| Módulos | Origem, eixos, semântica e conectores | Encaixe e estado invariáveis após crop |
| Montagem | Reutilizar catálogos e consumidores reais | Obra e água aparecem uma vez, no sítio certo |

## Dimensão, fase e geração

O plano ambiental 640×360 a 2× é uma hipótese inicial, não uma nova regra global. `517/2=258,5` e `618,5/2=309,25`: guardar domínio, origem local, âncora de mundo, passo e fase. A política de apresentação fica explícita e separada da simulação. Atores mantêm as suas próprias resoluções.

Consultar o snapshot OpenAPI e a documentação atual antes de executar. O pacote contém planos sem rede, não payloads finais com anexos resolvidos:

- `generate-image-v2`: dimensão explícita e até quatro referências; validar combinações de tamanho e resposta. Estilo e assunto separados não tornam a identidade matematicamente fixa.
- `generate-with-style-v2`: saída quadrada deduzida das referências no schema consultado. Não encaminhar automaticamente um panorama para ela.
- `image-to-pixelart`: `output_size` explícito, cada lado entre 16 e 512. Ensaiar `fixer` e `init_image_strength`; força máxima pode conservar precisamente o acabamento a substituir.
- `image-to-pixelart-pro`: tamanho automático. Explorar resultado sem alegar cumprimento de dimensão não controlada.
- Tileset lateral: terreno/plataforma, sem assumir rampas ou um kit universal de construções. O Building Pro documentado enumera outras projeções.

Uma camada 640×360 pode exigir particionamento de conversão: duas regiões 352×360 com sobreposição 64 resultam em 640. Ambas usam mestre, coordenadas e faixa protegida comuns. A aritmética não garante a costura artística. Preferir uma operação compatível com a dimensão quando disponível.

Não converter uma cena inteira com atores pequenos embutidos como se todos tivessem o mesmo orçamento. Produzir por planos e objetos, e rever a montagem. Registar dimensão pedida e recebida separadamente.

## Reparo localizado e estados

Máscara interna: `true` significa editável. Cada adaptador traduz essa convenção. Contexto pode exceder a área autorizada; compor localmente sobre o mestre e comparar fora da máscara depois de paleta, contorno, crop e exportação.

Se a chaminé estiver incorreta, registar uma exceção nessa ligação. O reparo não autoriza trocar a cobertura ou duplicar uma porta. Noite, neve e dano conservam a identidade, salvo mudança estrutural prevista. Consumir os estados e `BuildingSkins.shown_level` reais e a precedência existente de `RenewalArt`, sede, originais/pintura/fallback.

Para cada peça, conservar apoio local, crop offset, extensão de contacto, aberturas, conectores e estado×nível. A relação `world = anchor_world - anchor_local + pixel_local` precisa de sobreviver às transformações de exportação.

## Continuidade e prova

Manter Wang16 para a sua codificação atual. Validar os 64 pares horizontais e 64 verticais compatíveis. Outros sistemas requerem mapeamento próprio: dezasseis imagens não provam equivalência. Declarar os eixos de repetição; uma faixa X não precisa de repetir em Y. A heurística relativa de `tiles.seams` não prova diferença zero nem correção topológica.

A bancada do piloto deve mostrar conceito, mestre 1×, ampliação inteira, máscaras, diffs, peça isolada e montagem de dia/noite com os mesmos atores. Rever forma, material, função, escala, estado e continuidade separadamente. Uma nota global não pode compensar uma porta bloqueada.

Casos necessários: dimensão ausente bloqueada; panorama recusado numa rota quadrada; alfa parcial identificado quando o contrato pede alfa binário; hash não aprovado não promovido; reparo com um pixel fora da máscara rejeitado; origem preservada após crop; conector alterado localizado; plano oculto não revela buraco com câmera móvel; mesma oficina conserva apoio e portas entre estados; noite mantém leitura dos atores e moedas.

O pacote desta revisão valida ficheiros, hashes, aritmética dos planos e limites declarados. Não executa esses futuros testes da Forja, benchmark no Godot ou chamada PixelLab. O ensaio real posterior deve registar schema, inputs, job, saída, dimensões e custo reportado dentro da autorização e orçamento da sessão de implementação.
