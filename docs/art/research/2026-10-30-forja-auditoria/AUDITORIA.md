# Auditoria da Forja — sprites, poses e animações

Data: 30 de outubro de 2026. Base auditada: `a145f8ca226b240a5a7afc8ecc1f408b2c04be16`, após o PR #136.
Pedido: auditar e refinar como a Forja cria e molda sprites e animações.

## Resultado

A Forja já tinha regras de identidade, escala, equipamentos, perdas e revisão do dono. A principal lacuna
encontrada foi a diferença entre o caminho do sprite individual e o da prancha animada. A animação podia
passar por operações e exportações que não conservavam as mesmas informações de origem e revisão.

Esta intervenção corrige falhas reproduzidas, torna o plano de poses parte do pedido e melhora a inspeção.
Não demonstra que um gerador passou a desenhar automaticamente boas mãos, rostos ou intermediários. Essa
conclusão exige produzir e rever uma amostra real contra o conceito escolhido. Não houve geração paga,
redesenho dos personagens, alteração de assets em `art/` ou aprovação artística nesta auditoria.

## Falhas confirmadas e correções

| Caso | Comportamento anterior | Correção implementada | Onde |
| --- | --- | --- | --- |
| F01 — pose fiel contraditória | O pedido de animação fiel mandava conservar a mesma pose e gesto do conceito. | Conservar câmara, identidade, proporções e invariantes; as articulações seguem a timeline. A regra estática continua válida para uma pose única. | `constraints.py`, `prompts.py` |
| F02 — planeamento insuficiente | Havia contagem e nota genérica por ação; não havia plano estruturado das chaves. | `animation_plan/1` regista tela, pivô, contactos, antecipação, ação e recuperação já definidos nas bibles. O prompt exige braços ligados, peso, pega e oclusão. | `choreography.py` |
| F03 — tempo incompleto | `zip(rects, durations)` podia omitir quadros no JSON; zero, negativos e intervalos inválidos não tinham validação comum. | Um tempo válido por quadro; telas iguais; tags válidas, únicas e sem quadros órfãos, antes de escrever. | `timeline.py`, `anim.py` |
| F04 — contagem declarada diferente | `anim` truncava tags maiores e deixava poses adicionais fora de tags. | Exportação direta recusa divergência. Prancha gerada conserva diagnóstico, marca excesso como `unassigned` e não passa o contrato. | `timeline.py`, `cmd_make.py`, `sheetforge.py` |
| F05 — repetição/direção da prévia | GIF `loop=1` repetia uma vez; APNG repetia para sempre; a tira não seguia a direção da tag. | Ataque/morte reproduzem uma vez; reverse/pingpong usam a ordem real e os tempos correspondentes; cada tag tem prévia própria. | `anim.py` |
| F06 — APNG e frames completos | A prévia usava descarte do frame para fundo, incluindo o frame inicial. | Frames completos usam descarte NONE e blend SOURCE; os testes descodificam os pixels e os tempos. | `anim.py` |
| F07 — correção entre ações | Deflicker/lock atuavam sobre a tira inteira, podendo usar idle como referência de hit/die. | Cada ação tem a sua referência; a correção nunca atravessa a fronteira da tag. | `sheet_audit.py` |
| F08 — cabeça colada sobre outra pose | O lock comparava apenas pixels opacos do molde; podia sobrepor uma cabeça a outra silhueta/oclusão e reabrir um olho declarado como ação. | Exige pegada alfa compatível, cabe na tela e preserva áreas de ação e proteção. Os restantes casos ficam sem alteração, com motivo. | `motion.py`, `sheet_audit.py` |
| F09 — informação de origem perdida | A prancha não conservava `owner_rules`, cadeia ou perdas por quadro. | `animation_lineage/1` conserva hashes de entrada/atlas/quadros, consulta original, perdas, colocação e cadeia anterior. Redução herdada continua diagnóstica. | `sheet.py`, `sheet_audit.py`, `lineage.py` |
| F10 — opções ignoradas | Redução, células e método não chegavam integralmente à extração; `scale=1` podia voltar a ser estimado. O CLI da prancha não expunha modos de contorno/cadeia. | Opções chegam ao amostrador; células exigem pixels quadrados; grade nativa declarada fica a 1×. O CLI expõe as opções. | `sheet.py`, `sheetforge.py`, `cmd_make.py` |
| F11 — pose invisivelmente diferente | RGB diferente sob alfa zero podia contar como movimento ou raster distinto. | Comparação de poses normaliza apenas RGB completamente invisível. | `timeline.py`, `review.py`, `anim.py` |
| F12 — inspeção da tira | O leitor repetia a tira inteira, misturava ações no onion skin e podia deixar temporizadores ativos ao pausar. | Seleção de ação, escala 1×/inteira, fundo claro/escuro, paragem das ações sem ciclo e cancelamento do temporizador. | `report.py` |

Os testes de regressão estão em `tools/forja/tests/test_auditoria_animacao.py`. Foram executados contra os
comportamentos anteriores para confirmar as falhas, antes das correções. O registo da validação está em
[`verificacao.json`](verificacao.json). As provas anteriores continuam no `make forja`.

## Auditoria da criação do sprite

### Identidade e escala

O catálogo e a referência escolhida são a autoridade. Tropas e escudeiros atuais usam os contratos 64×64;
Rei/Arqueiro Real e restantes personagens grandes seguem o contrato explícito 80×80. Não inferir que um
arqueiro de tropa é o Arqueiro Real. Papel, tela, caixa ocupada, escala dos pixels e escala na cena são
medidas diferentes. Uma imagem 80×80 pode conter um corpo pequeno; não se resolve isso esticando-o.

O orçamento tem de reservar espaço para cabeça, expressão, mãos, equipamento e margem do gesto máximo.
Não impor percentagem arbitrária de ocupação. Uma pose sentada fica mais baixa; não deve ganhar cabeça
maior para preencher a caixa. Uma referência já pixelizada deve ter a sua grade recuperada antes de
qualquer redesenho; uma ilustração detalhada precisa de construção na grade final, em vez de redução.

### Contornos e clusters

A revisão deve começar pela silhueta e pelos grupos que descrevem volume. Verificar ritmo das diagonais,
junções, espessuras intencionais e contorno interno junto de mãos, pescoço e objetos. `outline auto` é uma
operação de compilação; não decide quais espessuras são bonitas nem acaba um contorno artístico.

Para um mestre já desenhado, `--outline keep` evita acrescentar um contorno por dilatação. Isso não
dispensa conferir as regras de cor/contorno do contrato: `finish` ainda aplica as opções de limpeza e
paleta escolhidas. Não tratar `keep` como garantia de igualdade byte a byte com a entrada.

O tutorial de cure descreve clusters, jaggies e banding. A aplicação ao Empire é contextual: um pixel
pequeno pode ser pupila, dente, brilho ou extremidade de uma corda. Não remover esses sinais com limpeza
global nem alisar uma diagonal sem verificar o significado do grupo.

### Rosto, mãos e objetos

A ficha facial deve ser feita a partir do conceito: olhar, pálpebras/sobrancelhas, boca, assimetria,
nariz da família da pele e pelos. Pinos extraídos do candidato só o protegem; não provam identidade.
O lock conserva uma região compatível; não cria atuação facial, nem resolve um ângulo novo da cabeça.

Desenhar ombro → cotovelo → punho → mão → pega → objeto como uma cadeia articulada. Verificar dedos à
frente/atrás, apoio do polegar e direção de peso. Na poção, ler bojo, gargalo, aro, rolha, líquido e brilho
em conjunto com a mão. Envelope ou contacto iguais não demonstram um frasco redondo nem uma boa pega.

Materiais precisam de planos de luz estáveis. A paleta do jogo é o contrato; alterações de rampas continuam
propostas separadas. Não voltar a impor um teto universal de cores nem reduzir tons até apagar dentes,
pupilas, pregas, brilhos ou separação dos metais.

## Auditoria das animações e do material em runtime

Foi inspecionado o primeiro quadro do elenco V15 integrado e medidos os atlas existentes, sem os alterar.
O [inventário medido](inventario-runtime.json) conserva contagens, caixas e tempos por ação. Esta observação
estática não equivale a ter revisto cada sequência em movimento, nem a reaprovar designs anteriormente rejeitados.

Os estudos V15 têm contagens/tempos experimentais diferentes das contagens canónicas. Isso já está
documentado nas bibles e continua a ser dívida de integração: não eliminar quadros para fazer a contagem
coincidir, nem alterar o contrato para legitimar automaticamente o estudo. A bailarina/Nia também não
devem ser promovidas como designs aceites apenas por estarem presentes no manifesto de runtime.

Para produção, resolver em ordem:

1. Abrir o conceito exato e confirmar função, tela, escala, invariantes e defeitos autorizados.
2. Desenhar um mestre na grade final e rever uma amostra pequena antes de expandir o elenco.
3. Planear cada ação: apoio, linha de ação, articulações, pega e oclusões nas chaves.
4. Desenhar passagens que expliquem o movimento entre as chaves. Uma rotação de recorte não fornece
   joelho, cotovelo, mudança de apoio ou tecido exposto.
5. Rever volumes e identidade por quadro. Preservar braços, barba/bigode no dano e objetos do conceito.
6. Conferir cada ação à velocidade real e em avanço manual; conferir emendas `idle → walk`,
   `idle → shoot → idle`, `sit → heal → stand`, `die → rise`.
7. Conferir pivô, sockets, evento de ação, cadência e passo contra a simulação. A animação não decide
   dano, cura, projétil, promoção ou moeda. No Sombra, flores crescem individualmente como efeito.
8. Guardar fonte, plano, consulta, perdas e observações da sequência exata. Testar importação no Godot.
   Não confundir raster válido, movimento revisto, aprovação do mestre e integração testada.

## Pesquisa web e limites do PixelLab

Foram lidos os documentos públicos de Aseprite, Pillow, Godot, PixelLab e o tutorial original de cure.
A pesquisa pelo serviço web devolveu erros; a leitura das páginas públicas foi feita por GET direto,
sem sessões autenticadas. Não foram consultadas aulas em vídeo nesta tarefa.

| Fonte primária | Facto verificado | Aplicação à Forja |
| --- | --- | --- |
| [Aseprite: animação](https://www.aseprite.org/docs/animation/) e [tags](https://www.aseprite.org/docs/tags/) | Tags separam intervalos e direção de reprodução; desenho, timeline, onion skin e prévia são operações distintas. | Inspeção por ação e plano de poses; respeitar ordem real das tags. |
| [Aseprite: duração](https://www.aseprite.org/docs/frame-duration/) | Cada quadro tem duração própria em milissegundos. | Validar tempos e conservá-los no JSON, Aseprite e prévias. |
| [Pillow: formatos](https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html) | GIF sem repetição omite loop; APNG tem controlos próprios de repetição, blend e descarte. | Correção das prévias e descodificação dos pixels/tempos nos testes. |
| [Godot: SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) | A duração do frame é relativa à velocidade da animação. | Conservar a conversão já existente de ms para multiplicadores; não uniformizar tempos. |
| [cure: tutorial original](https://pixeljoint.com/forum/forum_posts.asp?TID=11299) | Clusters, ritmo das bordas, banding e jaggies dependem da organização dos pixels. | Refinamento por região, preservando sinais pequenos significativos. |
| [PixelLab: OpenAPI v2](https://api.pixellab.ai/v2/openapi.json) | Campos e limites públicos dos endpoints de imagem/animação. | Revalidar contrato e planear integração sem atribuir capacidades não ligadas à Forja. |

A OpenAPI mudou de hash desde a leitura anterior. O verificador existente conferiu os limites do backend
de imagem, sem divergências: [`pixellab-contract.json`](pixellab-contract.json). O hash no backend foi
atualizado. Isto prova compatibilidade com a especificação consultada, não execução real no servidor.

Na especificação atual:

- `/animate-with-text-v3` recebe uma primeira imagem, uma ação e opcionalmente uma imagem final; pede
  contagem par entre 4 e 16. Não corresponde diretamente a `attack 5` ou `die 7` do Empire. Não truncar
  ou duplicar quadros para disfarçar essa incompatibilidade.
- `/animate-with-skeleton-v3` pede o sprite inicial, a marcação dos 18 pontos da pose inicial e um
  esqueleto por quadro, entre 3 e 15. As imagens regressam na dimensão da referência; a referência não
  é um dos quadros devolvidos. O texto público alerta que marcação incompatível com a pose prejudica
  transparência e precisão de cor. Isto favorece um plano de articulações explícito, não o seu preenchimento inventado.
- `/animate-character` exige um personagem previamente criado naquele serviço. Não é equivalente a
  enviar um PNG arbitrário do nosso elenco e receber uma animação aprovada.
- O template de quadrúpede e a profundidade dos pontos precisam de corresponder ao animal; não aplicar
  automaticamente o corpo humano ao cavalo, javali ou carneiro.

No fecho do FORJA-17, esses endpoints estavam **sem integração de geração na Forja**. Ligar um deles requer um
adaptador com validação de pontos/contagens, budget/jobs sem repetição indevida de POST pago, conservação
da identidade e revisão dos quadros recebidos. Esta auditoria prepara e melhora o fluxo local; não chama
uma integração proposta de funcionalidade entregue.

## Critério para a próxima produção

Usar uma amostra com mestre nativo e uma ação antes de gerar um lote. O plano deve acompanhar o `expect`;
a prancha deve conservar a consulta e a cadeia. Rever rosto, mão/pega e objeto em cada quadro, além de
testar a ação completa. O portão do mestre estático continua a exigir fidelidade e revisão exatas.
A aprovação artística de sequências ainda é uma etapa explícita a concluir pelo dono; a nova cadeia
de animação não a concede.

## Implementação posterior — FORJA-18

Henrique pediu a implementação dos pontos pendentes. A [ADR 0104](../../../adr/0104-a-forja-gera-e-reve-animacoes-nativas.md)
e o [guia operacional](../../FORJA_ANIMATION.md) documentam o resultado:

- Adaptadores `text-v3` e `skeleton-v3`, mestre/pose final nativos, autoridade e poses validadas antes da rede.
- Jobs retomáveis, orçamento persistente e índice plano/job; nenhuma repetição automática de POST pago.
- Conservação dos quadros brutos e da ordem; retorno incorreto fica diagnóstico, sem adaptar contagens.
- Refinamento nativo por máscara em quadros explícitos, preservando os restantes e a cadeia anterior.
- Prova com conceito, ficha pendente por quadro/ação e `entrega-anim` ligado aos pixels e à timeline completos.
- Resolução explícita de perdas e aprovação separada de Henrique para o hash exato da sequência.

Os testes usam transporte falso e imagens sintéticas. Não houve geração paga, novos assets integrados
ou aprovação artística automática. `hit` 2 permanece no caminho de desenho nativo/prancha: não cabe
nos limites desses dois endpoints. A implementação fecha o fluxo de ferramentas; o resultado artístico
continua a exigir observação real, correção e decisão do dono.
