# Auditoria da Forja criada pelo Claude

Revisão de 23/10/2026 para Henrique Passos, em continuidade à pesquisa do PixelLab.
Código avaliado: `68ed1c87461f5d39dd21fb664eef2930ddeaac81`, incorporado pelo
[PR #117](https://github.com/henriquecoding/empire/pull/117).
Os achados são sobre esse commit; uma correção posterior exige nova verificação.

**Conclusão:** a Forja é uma base útil de processamento, contratos, exportação e
integração com agentes. Deve ser aproveitada. Ainda não demonstra qualidade de
geração comparável ao PixelLab, e o caminho automático contém falhas concretas
de integração e preservação da arte. Esta entrega documenta e reproduz os
problemas; não modifica os módulos de produção da Forja.

## 1. O que foi entregue e o que foi verificado

O Claude implementou uma CLI Python e um servidor MCP local, com compilador de
prompts, adaptadores OpenAI/Gemini/PixelLab, detecção de grade, remoção de fundo,
paleta, contorno, limpeza, divisão de pranchas, métricas, inpainting e
exportadores PNG/JSON/GIF/APNG/Aseprite/Godot. Os contratos incluem `royal_64`
e `royal_80`; portanto, os tamanhos de estudo pedidos já têm perfis que devem
ser reutilizados. O default `character_s2` é 96×96, não o perfil dos monarcas.

| Evidência | Resultado observado | O que permite concluir |
|---|---|---|
| PR #117 e `main` | Merge confirmado no commit acima | A implementação existe no repositório principal |
| [CI da implementação](https://github.com/henriquecoding/empire/actions/runs/39917391094) | `success` | Os portões configurados passaram naquele commit |
| `python3 -m unittest discover -s tools/forja/tests -t .` | 80 testes: 79 passaram, 1 ignorado por Godot indisponível neste ambiente | A suíte local passou; o teste de motor não foi repetido localmente |
| `python3 -m tools.forja prova` | 11/11 verificações passaram | Os casos sintéticos previstos funcionam |
| Sondas desta auditoria | Nove observações reproduzidas sem rede | Há lacunas não cobertas pela suíte original |
| Duas imagens comparativas já versionadas | Inspeção visual dos rostos e contornos | A quantização da grade perde características expressivas nesses exemplos |
| Geração real, custos e treino | Não executados nesta auditoria | Sem afirmação de qualidade, preço realizado ou desempenho de inferência |

O primeiro ensaio local da suíte encontrou paletas ausentes porque o checkout
era parcial. Após incluir `art/palettes`, a suíte passou. Esse problema do
ambiente **não** é atribuído ao código do Claude.

As sondas usam fixtures próprias, respostas simuladas e diretórios temporários.
Não enviam pedidos a fornecedores, não leem chaves e não modificam assets.
Para repetir:

```bash
python3 docs/art/research/2026-10-23-pixellab/reproduce_forja_findings.py
```

Saída registrada: [forja-audit-observations.json](forja-audit-observations.json).
Contexto de execução e publicação: [forja-audit-evidence.json](forja-audit-evidence.json).
O script registra o comportamento encontrado, não define que os bugs devam
permanecer. Após uma correção, transforme cada caso em teste do comportamento
desejado na suíte da Forja.

## Continuação implementada

O [refinamento FORJA-02](../2026-10-23-forja-pixellab/REFINAMENTO.md) liga F01–F09
a correções e testes de regressão. Esta auditoria e suas observações originais
permanecem como fotografia do commit auditado. As sondas exploratórias podem
agora interromper-se numa validação antecipada; a suíte `make forja` verifica
o comportamento corrigido. Nesta sessão posterior a inspeção privada da Vercel
funcionou e os SHAs dos deployments foram conferidos diretamente.

## 2. Prioridades

P1 significa corrigir antes de usar o caminho afetado em produção ou em lotes
pagos. P2 significa corrigir antes de ampliar o respectivo recurso. Não há
alegação de incidente de cobrança nem de perda de arquivos do usuário.

| ID | Prioridade | Problema | Evidência principal |
|---|---|---|---|
| F01 | P1 | Retry genérico repete POST de geração sem reconciliação | Quatro POSTs simulados após HTTP 503 |
| F02 | P1 | `auto` PixelLab usa resolução do gerador geral e perde a referência | 1920×1920 enviados; parâmetros nativos 96×96 disponíveis; referência ausente |
| F03 | P1 | Planejamento Gemini não corresponde ao pedido; guia de paleta não é anexada | 1920×960 previsto; 3:2/1K enviado; zero imagens anexas |
| F04 | P1 | Chroma key fixa do inpainting apaga azul legítimo | 64 pixels opacos viram transparentes com resposta idêntica à entrada |
| F05 | P2 | Limpeza altera detalhes de um pixel sem opção de preservação | Pixel isolado removido e furo preenchido mesmo com `noise=0` |
| F06 | P1 para ações aéreas | Ancoragem independente descarta deslocamento intencional | Salto de 4 px convertido em dois rasters iguais |
| F07 | P2 | `ok` da prancha não exige movimento nem revisão | `walk:2` com dois quadros iguais retorna `ok=true` |
| F08 | P2 | Exportador Godot ignora direção da tag | `reverse` sai como 0,1,2 em vez de 2,1,0 |
| F09 | P1 operacional | Polling PixelLab não tem prazo/cancelamento/retomada | Sonda interrompeu a 20.ª consulta ainda em processamento |

### F01 — repetição de POSTs de geração

Local: `tools/forja/backends/http.py`, `send`, a partir da linha 58.
O conjunto `RETRY` inclui 408, 409, 429 e vários 5xx. A política independe do
método HTTP. O transporte simulado respondeu 503 e recebeu quatro POSTs iguais.
O pedido da sonda não contém chave de idempotência; os adaptadores atuais
também não implementam um protocolo de reconciliação de geração.

Um erro recebido do gateway não prova que o trabalho não foi aceito pelo
fornecedor. Reenviar pode criar trabalhos duplicados e, dependendo do contrato
da API, custos duplicados. A sonda demonstra reenvio; **não mede cobrança**.
Uma chave inventada no cliente não resolve: o servidor precisa documentar e
honrar esse mecanismo.

Correção: distinguir submissão de geração e consulta de job. Repetir GET com
prazo, backoff e jitter. Para POST, permitir repetição apenas com garantias
documentadas do endpoint; em aceitação ambígua, persistir estado
`submission_unknown`, identificador local, hash da requisição e metadados
disponíveis. Reconciliar antes de submeter outra vez. Suportar limite de custo
por execução e mostrar tentativas ao operador.

Teste de regressão: servidor simulado aceita um trabalho e perde a resposta;
o cliente não cria um segundo trabalho automaticamente. Outro teste comprova
retry seguro de GET e respeito a `Retry-After`. Não transformar todo HTTP 5xx
em autorização de repetir geração.

### F02 — PixelLab automático usa o contrato errado

Locais: `tools/forja/cmd_ai.py`, `do_auto` linhas 92–108 e `generate_images`
linhas 43–59; `tools/forja/prompts.py`, `build` e `pixellab_params`.

`do_auto` escolhe o alvo `gpt-image` para qualquer backend diferente de Gemini.
O prompt compilado para `character_s2` tem imagem ampliada de 1920×1920.
`generate_images` encaminha essas dimensões ao `create-image-pixflux`, embora
o próprio compilador já tenha produzido `pixellab.image_size = 96×96`.
A documentação pública da operação Pixflux informa área máxima equivalente
a 400×400. O pedido capturado está fora desse limite; não se executou chamada
real para observar o erro remoto. Fonte: [OpenAPI v2](https://api.pixellab.ai/v2/openapi.json),
operação `/create-image-pixflux`.

Há uma segunda falha no mesmo fluxo: uma imagem fornecida via `--reference`
é lida, mas não entra no payload PixelLab. O prompt promete preservar uma
referência que o modelo não recebeu. O backend de baixo nível aceita
`init_image`; a função que o chama não faz o mapeamento.

Correção: tornar o planejamento específico por capacidade do backend. Para
PixelLab, usar dimensões nativas e controles da operação escolhida; mapear
referência de identidade, imagem inicial e paleta com semânticas explícitas.
Não passar todas as referências como se fossem intercambiáveis. Validar
restrições de área e campos antes de qualquer POST. Um `--model` diferente
também precisa de validação própria. Animação exige capacidade de animação
implementada ou uma declaração explícita de que se está pedindo uma prancha
estática; os três adaptadores estáticos atuais não cobrem a API temporal.

Testes: `royal_64` e `royal_80` devem enviar 64×64 e 80×80 no caminho nativo;
referência deve aparecer no campo documentado, com hash registrado; tamanho
inválido deve falhar localmente sem chamar o transporte. Preservar testes para
o default 96×96, sem reclassificá-lo como tamanho de monarca.

### F03 — Gemini recebe uma geometria diferente da que será recortada

Locais: `cmd_ai.py`, `generate_images` linhas 51–55 e `do_auto` linhas 96–111;
`backends/gemini_images.py`, `generate`; `prompts.py`, `pick_scale`.

Para `character_s2`, `walk:8`, o compilador prevê prancha 1920×960, proporção
2:1 e escala lógica 5. A chamada converte qualquer paisagem para 3:2 e deixa
`image_size` no default 1K. Depois, o extrator recebe a escala 5 prevista,
sem verificar se o raster retornado obedece àquela geometria. Essa divergência
é observada no payload; não depende de especular qual desenho o modelo fará.

Além disso, o prompt exige cores de uma amostra de paleta anexada. No caminho
automático sem `--reference`, foram anexadas zero imagens. `do_prompt` produz
guias em disco, mas `do_auto` não as cria nem as inclui no pedido. Acrescentar
um arquivo a uma pasta não o torna visível para o gerador.

Correção: selecionar primeiro uma combinação suportada de modelo, proporção
e resolução, calcular a disposição dentro desse raster e só então compilar
prompt e guias. Quando não houver escala inteira compatível, mudar layout ou
usar padding explícito com coordenadas registradas. Nunca esticar o personagem
silenciosamente. Após a resposta, validar dimensões reais e correspondência
da grade; recusar ou replanejar em vez de impor uma escala falsa.

Separar referências por papel: identidade, estilo, paleta e layout. Gerar e
anexar as guias prometidas quando suportadas; se não forem usadas, retirar a
alegação do prompt. A [documentação Gemini](https://ai.google.dev/gemini-api/docs/image-generation)
expõe seleção de proporção e resolução; isso não garante que o modelo cumpra
cada célula desenhada, portanto a resposta ainda exige validação.

Testes: conferir payload completo para layout 4×2; simular retorno com tamanho
diferente; conferir contagem e hashes das referências transmitidas; impedir
que `auto` declare grade conhecida quando ela só foi pedida em linguagem natural.

### F04 — edição destrutiva por colisão de azul

Local: `tools/forja/inpaint.py`, `run` linha 71 e `merge` linhas 41–56.
A chave é sempre `#0000FF`. O sprite é composto sobre esse fundo; após a
edição, a mesma cor é removida. Isso confunde roupa azul legítima com fundo.

A reprodução cria um quadrado azul de 8×8 sobre transparência. O backend
simulado devolve exatamente a imagem recebida. A sonda fixa ampliação 2× para
reduzir o custo local, sem alterar a chave ou o algoritmo de composição.
Dentro da caixa editada, os 64 pixels desaparecem. Fora dela, a igualdade
permanece verdadeira: a proteção externa funciona, mas não prova preservação
do conteúdo interno.

Correção: preferir alpha real em modelos que o suportem. Se for indispensável
chroma key, selecionar uma cor ausente e distante da paleta, registrar a
escolha e tratar colisões explicitamente. `matte.best_key` já é uma base local,
mas uma cor distante não impede o gerador de reutilizá-la; validar a saída.
O modo sem alteração deve reconstruir o original exatamente. Dimensões
inesperadas também precisam de erro explícito: `merge` hoje redimensiona-as
silenciosamente antes de aplicar a máscara.

Testes: round-trip sem alteração com azul, magenta, verde e transparência;
igualdade externa byte a byte; caixa nas bordas; máscara vazia; retorno com
tamanho errado; edição que introduz deliberadamente a antiga cor de chave.

### F05 — detalhes intencionais de um pixel não têm proteção

Locais: `tools/forja/pipeline.py`, `finish` linha 102;
`tools/forja/cleanup.py`, `despeckle` linhas 30–51.
O pipeline sempre elimina pixels opacos sem vizinhos opacos e preenche furos
transparentes de um pixel cercados por oito pixels opacos. `noise=0` desativa
apenas parte da correção cromática; não desativa essas duas transformações.

A fixture mostrou um ponto isolado passar de alpha 255 a 0, e um furo passar
de 0 a 255. O comportamento pode ser desejado para ruído, mas também remove
partículas, pólen, pontas desconectadas ou transparência intencional. Não se
afirma que todo olho de um pixel seja removido: um olho sobre face opaca tem
vizinhos opacos e não corresponde a esse caso.

Correção: separar `remove_orphans`, `fill_holes` e `color_denoise`; tornar a
política explícita por tipo de asset, com possibilidade de preservar pixels
e regiões revisadas. Mostrar um mapa de alterações antes/depois. Não impor a
mesma regra de cenário a efeitos e personagens.

Testes: fixture com partículas isoladas aceitas, furo legítimo, ruído removível
e máscara protegida. Verificar que o modo conservador é idempotente e que uma
segunda passagem não continua degradando a arte.

### F06 — alinhar todos os pés pode apagar a ação

Locais: `tools/forja/sheet.py`, `extract` linhas 168–197 e `frames` linhas
200–215; `sheetforge.py`, `forge_sheet` linhas 81–86.
Cada figura é recortada até sua área opaca e ancorada separadamente ao mesmo
pivô. A caixa de origem é registrada no relatório, mas não participa do
posicionamento final. A sonda forneceu duas células: a segunda figura está
4 pixels nativos acima da primeira. A exportação resultou em um único raster
distinto, deriva zero e `ok=true`.

Para uma caminhada em apoio, estabilizar uma linha de chão pode ser útil.
Para salto, voo, recuo, morte e crescimento, uma diferença de posição pode
ser parte essencial do desenho. `anchor=mass`, `bottom` ou `center` ainda
reancora cada recorte; trocar o nome da âncora não restaura a trajetória.

Correção: conservar o sistema de coordenadas da célula original e sua origem
por quadro. Separar pivô do personagem, referência do chão e deslocamento
visual. Oferecer modos explícitos: preservar origem, estabilizar apoio apenas
em quadros de contato, ou usar marcadores revisados. Conservar deslocamentos
de apresentação sem permitir que eles dirijam a simulação do jogo.

Testes: salto deve manter a diferença de 4 px; caminhada com pés alternados
deve preservar apoio sem oscilar o tronco indevidamente; personagem agachado
não deve ser ampliado para ter a mesma altura; crescimento de flores deve
manter a raiz e a progressão de cada flor. Deriva zero imposta pelo algoritmo
não pode ser usada como prova independente de boa animação.

### F07 — aprovação estrutural é usada como condição de parada

Local: `tools/forja/sheetforge.py`, `forge_sheet` linha 112;
`tools/forja/cmd_ai.py`, `do_auto` linhas 111–119.
`ok` verifica a contagem de quadros e o lint por imagem. As métricas de
duplicação são calculadas, mas não entram nessa decisão. A fixture de dois
quadros iguais, rotulada `walk`, recebeu `ok=true` e `distinct_rasters=1`.
O modo automático encerra a procura ao receber esse `ok`.

Isto não significa que o Claude tenha inventado quadros: o código conta as
figuras reais encontradas. A lacuna está em aceitar a contagem como condição
suficiente de conclusão do ciclo. Uma pose mantida pode ser intencional; por
isso, banir globalmente todo raster repetido também seria errado.

Correção: separar `contract_valid`, `motion_checks`, `needs_review` e
`artistic_approval`. Definir políticas por ação e permitir holds declarados,
com duração e motivo. Uma caminhada inteira estática deve pedir revisão ou
nova geração; uma pausa intencional não deve ser fabricada como movimento.
O estado de revisão já usado pelo Empire deve permanecer independente.

Testes: caminhada toda duplicada, hold explícito aceito, sequência com
intermediário ausente, braço desaparecido e ordem trocada. Os dois últimos
exigem também avaliação visual; testes estruturais não reconhecem anatomia.

### F08 — direção de reprodução perdida no Godot

Local: `tools/forja/godot.py`, `sprite_frames` linha 57.
A função recebe tags com direção, mas descarta esse valor e sempre itera
de `first` até `last`. A sonda textual recebe `reverse` e encontra referências
de textura 0,1,2, quando a sequência deveria ser 2,1,0. Não se abriu o motor
nesta sonda; o defeito já aparece no recurso emitido.

Correção: normalizar a ordem por tag antes de exportar: forward, reverse,
ping-pong e demais direções efetivamente suportadas. Para direção não
suportada, falhar claramente. Associar duração ao quadro correto após
reordenar. Preservar os endpoints e a regra de repetição do formato de origem.

Teste: três texturas identificáveis e durações 100/200/300 ms; conferir ordem
e tempo no texto e no recurso carregado em Godot. O caminho atual de
`sheetforge` emite tags forward; a falha atinge o contrato mais geral do
exportador, não toda exportação atual.

### F09 — trabalho assíncrono sem término controlado

Local: `tools/forja/backends/pixellab_api.py`, `generate` linhas 55–63.
Enquanto houver job e não houver imagem, o código consulta o status. Não há
prazo total, limite de consultas, cancelamento nem persistência para retomar
o job depois de reiniciar o processo. O timeout de uma requisição HTTP não
limita a duração total desse laço.

A sonda retorna `processing` e interrompe externamente na 20.ª consulta.
Ela não mede um timeout real nem prova uma falha do serviço: demonstra que
o cliente continua consultando sem um mecanismo próprio de encerramento.
Em produção, a espera entre consultas existe; com transporte injetado não há
espera, o que permite testar rapidamente o mesmo fluxo.

Correção: prazo monotônico global, cancelamento local, persistência imediata
do job, estados terminais documentados, polling limitado e retomada por ID.
Job concluído sem imagens deve ser um resultado de erro diagnosticável,
não sucesso vazio que fará o chamador falhar ao desempacotar a lista.

Testes com relógio falso: job preso, falha remota, sucesso vazio, estado
desconhecido, cancelamento e retomada depois de reinício. O job deve ser
consultado, sem novo POST, ao retomar.

## 3. O que está bem e deve ser preservado

Os contratos em dados e os perfis do Empire reduzem decisões implícitas.
A decomposição em módulos pequenos facilita corrigir adaptadores sem mexer
no runtime. O transporte injetável tornou possível reproduzir falhas sem
gastar créditos. A composição do inpainting preserva o exterior da caixa.
Paleta comum entre quadros, contagem de figuras, relatórios visuais e estados
de revisão são bases adequadas para um fluxo de produção.

Exportar `.aseprite` e recursos Godot é útil, e a prova de costura dos tiles
testa uma propriedade concreta. A suíte em CI é um avanço real. Entretanto,
um round-trip com escritor e leitor próprios pode compartilhar o mesmo erro;
complementá-lo com abertura no Aseprite e leitura no motor evita essa cegueira.
O teste de Godot no CI da implementação é evidência distinta da execução
local desta auditoria, que o ignorou por ausência do executável.

Não foi identificado um erro simplesmente porque o modelo OpenAI parecia
novo: `gpt-image-2.5-sunburst` foi confirmado na
[documentação oficial](https://developers.openai.com/api/docs/guides/image-generation)
consultada nesta data. Não substituir nomes válidos por modelos antigos com
base em memória. Disponibilidade da conta, comportamento efetivo e custos
continuam exigindo um ensaio autenticado controlado.

## 4. Onde a documentação é mais forte que a evidência

A pesquisa do Claude em `2026-10-23-forja-pixellab/` explica a implementação e
reconhece que não houve geração real. Algumas frases, porém, precisam de
qualificação na próxima revisão:

| Afirmação | Formulação sustentada |
|---|---|
| O modelo PixelLab desenha internamente na grade final | A API entrega pixel art nas dimensões solicitadas; a arquitetura interna atual não foi publicada nas fontes consultadas |
| Recuperar a grade devolve exatamente a cor pretendida pelo gerador | O algoritmo estima grade e escolhe uma representação discreta; regiões com detalhes abaixo da célula perdem informação |
| Forja supera outras ferramentas de recuperação | Há diferenças de algoritmo; superioridade exige o mesmo conjunto de imagens e critérios, com resultados comparados |
| PixelLab não faz crítica do resultado | Não foi demonstrada ausência geral dessa capacidade; descrever especificamente o lint de contratos do Empire que a Forja implementa |
| Prova sintética demonstra qualidade da arte | Demonstra comportamento nos tipos de distorção fabricados; qualidade de rosto, identidade e ação requer outros ensaios |

Nas comparações existentes, a bailarina mantém roupa e silhueta geral, mas
o sorriso vira uma marca pequena e os olhos perdem a forma expressiva. O rei
mantém atributos reconhecíveis, mas sobrancelha, olhos e sorriso mudam com a
discretização. Isso é visível em
[Sombra/bailarina](../2026-10-23-forja-pixellab/comparacao-sombra-bailarina.png)
e [rei/escudeiro](../2026-10-23-forja-pixellab/comparacao-rei-escudeiro.png).
O próprio relatório do Claude reconhece a perda do rosto da bailarina.

Essas imagens são recortes comparativos de pranchas preexistentes, não um
benchmark novo de personagens 64×64/80×80 gerados com a Forja. Não extrapolar
um score de grade para a preferência artística de Henrique. Para o estilo
cômico pedido, perder sobrancelha, sorriso e direção do olhar pode eliminar
justamente a qualidade mais importante, mesmo com contorno e paleta corretos.

## 5. GitHub, Vercel e o produto que está publicado

O status Vercel associado ao commit do PR #117 estava `success`, com destino
[neste deployment](https://vercel.com/hamriki-s-projects/empire/Ct35X8mt6mW6NfFADMy8NKu5jEmy).
O site público [Empire](https://empire-phi-eight.vercel.app/) respondeu HTTP 200.
As rotas `/en/`, `/jogar/` e `/dossie/` também responderam 200. A página inicial
e a inglesa continham a referência à Forja e o marcador `68ed1c8`.
Os arquivos JavaScript, WASM e PCK declarados pela página de jogo tiveram
verificação HTTP separada, registrada no arquivo de evidências.

Isso comprova disponibilidade HTTP dos documentos e arquivos consultados.
Não comprova jogabilidade completa no navegador, chamadas de geração,
qualidade de assets ou configuração de credenciais do servidor.

A Forja entregue é uma ferramenta local CLI/MCP em `tools/forja`, não um
editor web de geração hospedado na Vercel. Exibir o trilho FORJA no painel
do projeto é informação de andamento; não cria uma API web da ferramenta.
Essa distinção evita tomar publicação do site como publicação de um produto
equivalente ao PixelLab.

A inspeção privada da Vercel retornou **403 por falta de acesso ao escopo
`hamriki-s-projects`** na conexão disponível. Portanto, logs privados,
variáveis, proteção, configuração interna e associação completa de domínio
ao deployment não foram auditados. O mecanismo de autorização indicado pelo
serviço não estava exposto nesta sessão. A limitação fica registrada sem
atrasar a análise do código e da superfície pública.

Se houver objetivo posterior de editor web, acrescentar autenticação,
armazenamento durável, fila de jobs, orçamento por usuário, progresso,
cancelamento, retomada e revisão visual. Segredos de fornecedores ficam no
servidor. Worker de geração e pós-processamento deve ter vida independente
da conexão HTTP do navegador. Essa é uma proposta futura, não uma descrição
do deployment atual. Não há necessidade de construir essa interface para
validar primeiro a qualidade da Forja local.

## 6. Como continuar sem refazer o que já existe

O [relatório mestre](RELATORIO-MESTRE.md) detalha a arquitetura, treinamento,
dados e experimentos para um sistema independente. Ele deve ser aplicado
sobre a Forja existente. Não criar um segundo conjunto de exportadores,
contratos e ferramentas de acabamento com outra fonte de verdade.

| Ciclo proposto | Trabalho concreto | Critério de saída |
|---|---|---|
| A — requisições confiáveis | F01/F02/F03/F09; plano por backend; validação; jobs duráveis | Payloads corretos, nenhum POST ambíguo reenviado automaticamente, retomada sem gerar de novo |
| B — preservar a arte | F04/F05/F06/F08; coordenadas, máscaras e direção | Fixtures preservadas, round-trip exato quando nenhuma alteração é pedida |
| C — avaliação honesta | F07, estados de revisão, relatórios por ação e correção das alegações | `contract_valid` não é confundido com movimento aceito nem aprovação do autor |
| D — piloto real | Modelo disponível, referências autorizadas, `royal_64`/`royal_80`, teto de gasto | Todas as saídas preservadas, custos e retrabalho medidos, falhas visíveis |
| E — melhoria condicionada | Referência/pose, edição local, paleta aprendida ou ajuste de estilo | Ganho medido sobre baseline, sem degradar identidade ou movimento |
| F — modelo próprio | Dados licenciados, splits, treino e ablação do relatório mestre | Melhor taxa de aceitação e custo total justificando treino e manutenção |

Para o piloto, usar [benchmark-plan.json](benchmark-plan.json). A amostra
inicial é menor que o estudo completo e não foi executada aqui. Antes de
gastar, estabelecer teto explícito, configuração imutável e um registro de
falhas e tentativas. Disponibilidade de credencial não equivale a orçamento
ilimitado. Não iniciar centenas de chamadas para descobrir um erro de tamanho
que um teste de contrato poderia encontrar sem rede.

A unidade útil é o asset aceito: custo de geração, número de tentativas,
minutos de correção, preservação de rosto, consistência de equipamento,
qualidade de movimento e sucesso de integração. Comparar imagens ampliadas
por nearest em 2× e também em 1×; a legibilidade real depende do tamanho de
uso. Em clips, revisar pose, transição, contato, timing e loop em movimento.

Para os problemas específicos já relatados por Henrique, incluir casos
obrigatórios: braço e mão presentes em todos os quadros, arma com continuidade,
rosto cômico reconhecível, intermediários reais, e flores que crescem
individualmente com raiz estável. Rotacionar uma flor pronta não satisfaz
esse último caso. A decisão deve ser visível no relatório de revisão, não
deduzida de um score agregado de pixels.

Proposta de contrato de backend: `capabilities`, `plan`, `submit`, `poll`,
`fetch` e `cancel` quando o fornecedor permitir. `plan` retorna dimensão de
saída, canvas nativo, layout, transformações reversíveis, referências por
papel e limites. `submit` devolve recibo persistível; `fetch` devolve raster
real e metadados medidos. Um plano não executado nunca deve aparecer como
arte produzida. Adaptar essa proposta às interfaces existentes em passos
pequenos, com ADR apenas quando as regras locais o exigirem.

O registro de cada geração deve incluir modelo e versão disponível, backend,
hash do prompt, hashes das referências, seed quando suportada, parâmetros
efetivos, dimensões pedidas e recebidas, job ID, tentativas, tempos, custo
conhecido ou explicitamente desconhecido, licença/permissões e revisão.
Preservar a saída bruta e cada transformação. Não registrar credenciais.

## 7. Entrega para o próximo ciclo do Claude

Começar por [PROMPT-PARA-CLAUDE.md](PROMPT-PARA-CLAUDE.md). O primeiro objetivo
é corrigir a Forja e demonstrar um ciclo real de um personagem, sem anunciar
equivalência ao PixelLab antes do benchmark. A implementação já oferece
infraestrutura suficiente para esse avanço; o gargalo agora é preservar
informação visual, alinhar cada adaptador à API correta e medir resultados.

Esta auditoria termina com problemas reproduzíveis, prioridades, caminhos de
código e critérios de teste. Permanecem pendentes as correções de produção,
o ensaio autenticado com geradores, a avaliação artística do piloto e a
inspeção privada da equipe Vercel sem acesso nesta sessão.
