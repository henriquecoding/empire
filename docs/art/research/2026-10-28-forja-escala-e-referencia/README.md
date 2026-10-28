# Forja — auditoria da escala, das referências e do refinamento

28/10/2026. Base examinada: `addac399dee51b9f534defffcebe72dadac4b839` (`main`). Implementação: FORJA-09,
ADR 0096. O pedido de Henrique corrige explicitamente o arqueiro de tropa para 64×64, exige corrigir o erro
visual da arma presente na referência e manter o Rei dentro de 80×80, com melhor acabamento dos pixels.

## Resultado e limite

Foram corrigidos caminhos de decisão, preservação e validação da Forja. A ferramenta escolhe a tela da tropa
antes da geração; recusa conflitos entre papel, preset e autoridade; mede o vazio separadamente do desenho;
conserva a leitura nativa 1×; deixa de dar `ok` quando perdeu um sinal obrigatório; incorpora exceções para
defeitos da referência e verifica ligações do arco que a reta da corda não provava.

Há uma rota nova de conversão com `output_size` nativo, em vez de pedir uma imagem grande por palavras e
tentar fazê-la caber depois. O contrato HTTP foi conferido com a especificação pública atual, cujo SHA-256
continua `b6dd212ca4e7f60c9eb93e776303a92f6e0bb4f794cf3a2bf49099e9a00e8834`. Não houve chave PixelLab
configurada, chamada paga ou validação visual de uma conversão real. Os ensaios de rede são simulados.

Não há novos mestres aprovados nem alegação de que um detector ou um conversor resolveu automaticamente a
identidade. Os arquivos do jogo não foram reescalados; não se escreveu em `art/`, `audio/`, `src/`, `scenes/`
ou `data/`. As referências antigas em `research/` continuam históricas, com o seu estado original.

## 1. O Rei excedeu a tela por causa de pixels vazios?

Não, segundo a extração estimada registrada na entrega. A medição foi refeita com alfa ≥128, distinguindo
resíduos quase invisíveis do conteúdo que a Forja considera opaco:

| Arquivo examinado | Tela | Caixa opaca | Linhas vazias acima / abaixo | Significado |
|---|---:|---:|---:|---|
| Imagem grande do Rei | 1254×1254 | 1220×1214 | 16 / 24 | Margens do raster grande, já removidas na extração |
| Rei extraído, sem corte | 97×96 | 97×96 | 0 / 0 | O próprio desenho excede 80×80 |
| Escudeiro extraído | 64×64 | 51×54 | 9 / 1 | Cabe, mas não usa 64 linhas de desenho |
| Arqueiro de tropa entregue | 80×80 | 65×77 | 2 / 1 | Tela errada para a classe; precisa de reconstrução em 64×64 |

No Rei extraído há 5.930 pixels opacos e 3.382 transparentes dentro do retângulo 97×96. Esse vazio é sobretudo
o espaço entre a silhueta e as bordas ou entre partes do corpo. Ele não permite apagar 17 colunas e 16 linhas
inteiras sem mover ou destruir desenho. O espaço externo da prancha de comparação é de apresentação.

Os 97×96 são uma **estimativa de grade**, com confiança registrada de 0,429, não o arquivo nativo original
recuperado exatamente. A imagem gerada não tem uma grade uniforme comprovada. Isso reforça a necessidade de
autoria/conversão controlada na tela final; não autoriza escolher arbitrariamente uma grade mais grossa para
que os números passem. `snap.occupancy` agora documenta tela, caixa útil, margens, pixels e vazio interior.

## 2. Achados e correções

| ID | Falha reproduzida | Correção implementada | Prova principal |
|---|---|---|---|
| C01 | Arqueiro de tropa recebia preset real 80×80 | Papel `troop` resolve `troop_64`; Rei/Arqueiro Real/escudeiro têm papéis distintos | `RoleTest`, prova `troop_native_64` |
| C02 | `--kind` podia contradizer silenciosamente o contrato de fidelidade | Conflito explícito no plano/prompt e até ao `forge --expect` | `test_fidelity_and_requested_kind_cannot_silently_disagree` |
| C03 | Orçamento útil ficava por planejar; o corte era descoberto no fim | Caixa útil completa no contrato, no pedido e na conferência final | `target_useful_bbox`, `limits.useful_budget` |
| C04 | Copiar o conceito também copiava defeitos conhecidos | `reference_issues`: bloquear dúvida, autorizar reparo localizado ou registrar intenção | `ReferenceRepairTest` |
| C05 | Uma corda reta podia estar presa no vazio, sem chegar à madeira | `bow_nocks` confere pontas e posição da pega; curvatura normal do arco continua aceita | Controles de arco válido e madeira afastada |
| C06 | A leitura declarada a 1× reajustava linhas e podia deformar pixels já nativos | Grade 1× inteira, sem reestimar fase ou linhas | `test_native_one_to_one_preserves_every_visible_pixel_before_finishing` |
| C07 | Sinal obrigatório bloqueado não fazia o `forge.ok` falhar | Achado `required_signal` de erro, antes do resumo e da exportação | Pinos de cores conflitantes na mesma célula |
| C08 | Feedback ainda pedia dois tons e rostos reduzidos a marcas de 1–2 pixels | Feedback preserva o sistema facial, dobras e planos; sem limite genérico de tons | Teste do prompt corretivo |
| C09 | Geração PixelLab e `pixellab.json` perdiam instruções completas de fidelidade; parâmetros impunham shading básico | Texto nativo comum preserva invariantes/exceções; modo fiel omite shading/detail implícitos | Teste do plano nativo e JSON compilado |
| C10 | Não havia ligação para converter conceito grande com tamanho de saída nativo | Modelo `image-to-pixelart`, `fixer=true`, `output_size` estruturado; sem resize local | `NativeConversionTest` e descritor em `prova.json` |
| C11 | Falha de encaixe ainda deixava um PNG cortado com nome de candidato | Diagnóstico `uncut_png` e estado `delivery` bloqueado; erro de tamanho também bloqueia esse estado | Ensaio 97×96 e controle negativo de resposta 65×64 |
| C12 | Tentativa de corrigir conversão poderia repetir o mesmo POST pago, pois a rota não aceita texto | Interromper após falha; não repetir pedido idêntico como se tivesse recebido correção | Transporte falso conta exatamente um POST |

### Um erro adicional que não explica retroativamente toda a entrega

O C06 foi encontrado com uma figura sintética numa tela 100×100. Havia um retângulo útil de 80×70 pixels.
O caminho antigo com `--scale 1` reajustava a grade para 87×95 células e entregava um recorte 77×67. A leitura
corrigida conserva a grade 100×100 e os 80×70 pixels úteis. Um segundo controle compara cada byte RGBA de uma
região colorida nativa. Esse defeito poderia estragar saídas de APIs nativas; não foi usado para explicar o Rei
grande, que seguiu detecção estimada, não leitura conhecida a 1×.

## 3. A referência é autoridade de identidade, mas pode conter um erro

A referência do arqueiro tem uma região cinzenta semelhante a uma lâmina entre as mãos, sem uma parte do arco
identificada, e uma corda cuja continuidade inferior não fica comprovada no trecho visível. A observação é
manual e a incerteza deve permanecer explícita: uma manga pode ocultar uma corda, mas a oclusão não prova que
a construção por baixo esteja correta. Não se afirmou que toda parte pouco visível está ausente.

O contrato de 28/10 conserva rosto, capuz verde, roupa creme, proporções e gesto em repouso; registra essas
regiões como exceções para correção. A instrução pede arco de madeira coerente, pega entre as duas pontas,
uma corda clara e ausência do fragmento sem função, com oclusões declaradas. Não troca o arqueiro de tropa pelo
Arqueiro Real nem altera a roupa para justificar a arma.

A documentação da World Archery distingue pega, dois membros/pontas e corda ligando as extremidades [1]. Isso
serve como referência funcional, não como exigência de copiar um arco olímpico ou eliminar estilização. O
novo teste não impõe simetria perfeita ou arco vertical; confere contato e a posição da pega entre as pontas.

`reference_issue_reviews` exige o ID do defeito, hash dos pixels do candidato, autor, data, resultado e
observação. Uma edição posterior invalida a prova pelo hash. Um `pass` genérico de identidade não substitui
essa prova. Se a referência foi corrigida, a derivação e a máscara precisam ser preservadas; o conceito
original continua disponível para comparar a identidade.

## 4. Gerar realmente na grade

As três operações não são intercambiáveis:

| Operação | Controle verificável | O que ainda não garante |
|---|---|---|
| Ferramenta de imagens embutida, imagem grande | Texto e medição posterior | Obediência a 64×64/80×80 nativos ou uniformidade das células |
| `create-image-*` do PixelLab | Campo nativo de largura/altura | Identidade, anatomia, equipamento ou aceitação de uma referência grande |
| `image-to-pixelart` padrão | `image_size` da fonte e `output_size` nativo, `fixer` | Correção semântica da arma, preservação de cada feição e paleta do projeto |

Na especificação pública conferida em 28/10 [2], a conversão padrão aceita fonte de 16–2048 por lado e saída
de 16–512, e documenta `fixer` e força inicial 0–999. A faixa útil descrita pelo fornecedor é 100–300; não há
evidência de que um valor máximo produza automaticamente melhor pixel art. A Forja registra 200 por omissão
ou o valor explícito válido; não os troca silenciosamente. Não há campo textual nessa rota.

Por isso, a conversão recusa uma fonte com reparo semântico conhecido ainda por fazer. Converter fielmente
um arco errado preservaria o problema. A fonte deve primeiro passar por edição localizada e verificação;
uma redução local não passa a ser um mestre nem prova que houve conversão pelo modelo. A API não foi
executada nesta sessão, e os pedidos de teste não usaram créditos reais.

O artigo de Wu e colaboradores separa estrutura de célula e efeitos de aliasing e usa uma referência para
condicionar essa estrutura [3]. A consequência para a Forja é distinguir controle de modelo de medição
posterior; o artigo não prova que um prompt numa ferramenta geral impõe a mesma grade.

## 5. Refinar pixels preservando desenho

Muitas variações de RGB, células com alta pureza e fragmentos pequenos não têm o mesmo significado. Um
pixel isolado pode ser a pupila, um dente, uma ponta ou ruído. Uma cor parecida com a vizinha pode pertencer a
outro material. Uma linha diagonal deve ser analisada com conectividade adequada, não apagada por parecer
uma sequência de pontos.

O estudo de Gerstner e colaboradores combina escolhas de posição e paleta com mapa de importância e
restrições por pixel/cor [4]. Ele não equivale a aplicar nearest-neighbor e quantizar. Saint11 trabalha
agrupamentos, refinamento de contornos e detalhes; também distingue pixels órfãos úteis de ruído [5]. Essas
fontes apoiam preservar função e regiões críticas, sem impor uma limpeza cega ou um limite universal de tons.

Aplicação à próxima reconstrução:

1. Resolver corpo e equipamento dentro da caixa nativa; reservar espaço para o sistema facial e mãos.
2. Marcar pálpebra/pupila/sobrancelha/nariz/boca juntos, não uma coleção de dentes acrescentada ao final.
3. Identificar materiais e rampas antes de fundir cores. Proteger rosto, mãos, corda e contatos confirmados.
4. Corrigir o menor conjunto funcional inteiro: arco, suas duas pontas, pega, corda e mão; depois microdetalhes.
5. Refinar contornos e agrupamentos por regiões, inspecionando 1× e ampliação inteira em fundos diferentes.
6. Repetir a prova de pixels externos preservados, sinais críticos e equipamento depois do último acabamento.

O código não implementou o algoritmo integral de nenhum artigo nem um novo modelo treinado. A capacidade de
entender um fragmento desconhecido ainda depende da observação visual do agente/artista; as verificações
geométricas trabalham nas regiões observadas e não fingem localizar objetos sozinhas.

## 6. Reproduzir e interpretar a validação

```bash
python3 docs/art/research/2026-10-28-forja-escala-e-referencia/prova_escala.py
python3 -m unittest tools.forja.tests.test_escala_referencia tools.forja.tests.test_ocupacao_conversao
make forja
```

`prova.json` é produzido pelo primeiro comando, com controles positivos/negativos e zero chamadas de rede.
O `make forja` repete a suíte e as provas históricas; os JSONs históricos receberam somente o novo achado
`bow_nocks`, sem mudança dos pixels dos estudos. A extensão de grade do Rei foi medida nos arquivos da
entrega anterior, não inferida de uma miniatura. O pacote anterior é a fonte reproduzível desses arquivos:
[Forja-Teste-Fidelidade-2026-10-28.zip](https://chatgpt.com/library?file_id=libfile_84b72805777881919f6645ee2afa7b5d&account_id=personal).

O motor Godot não está instalado no ambiente desta auditoria. A tentativa de executar `./run_tests.sh`
encerrou com `godot: command not found`; a revisão de integração depende do CI com o motor fixado. Isso não
foi contado como teste aprovado. Não houve edição de GDScript ou integração de assets nesta tarefa.

## Fontes primárias lidas e aplicação

[1] World Archery. *Recurve — Equipment*. Pega, membros e corda; fundamento funcional do contato das pontas.
https://www.worldarchery.sport/sport/equipment/recurve

[2] PixelLab. *OpenAPI v2*, endpoint `/image-to-pixelart`, schema `ImageToPixelartRequest`, consultado 28/10/2026.
GET público, sem autenticação ou geração. Hash registrado no início. Fonte do pedido estruturado e dos limites.
https://api.pixellab.ai/v2/openapi.json · https://api.pixellab.ai/v2/docs

[3] Wu et al. *Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization*. ACM TOG 41(6), 2022.
Página institucional e resumo lidos; não foi executado o modelo. DOI: 10.1145/3550454.3555482.
https://researchportal.bath.ac.uk/en/publications/make-your-own-sprites-aliasing-aware-and-cell-controllable-pixeli/

[4] Gerstner et al. *Pixelated Image Abstraction with Integrated User Constraints*. Computers & Graphics 37(5),
2013, 333–347. Resumo e seções de método/controles recuperados na publicação; portal do autor retornou timeout.
Não foi implementado o algoritmo completo. DOI: 10.1016/j.cag.2012.12.007.
https://www.sciencedirect.com/science/article/pii/S0097849313000046

[5] Saint11. *Cluster Sketching and Painting*, 2021. Agrupamentos, contornos e detalhes úteis; aplicação editorial
ao elenco, sem importar a paleta ou a câmera do exemplo.
https://saint11.art/pixel_art_articles/article2/

[6] Retro-Diffusion. *pixel-art-fixer / HOW_IT_WORKS*. Documentação do implementador sobre ambiguidade de
harmônicos, conteúdo versus grade e deriva. Foi usada para orientar a auditoria da estimativa; não houve
importação do código ou incorporação de uma dependência nova.
https://github.com/Retro-Diffusion/pixel-art-fixer/blob/main/docs/HOW_IT_WORKS.md
