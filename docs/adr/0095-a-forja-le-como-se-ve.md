# ADR 0095 — A Forja lê a imagem como se vê, vota sem fronteiras de balde e conta o gasto entre processos

- Estado: aceite
- Data: 2026-10-27
- Secção do dossiê: §01 e §22 (a unidade gráfica, a paleta, o contorno)
- Complementa: ADR 0088 (a Forja), ADR 0089 (pede uma vez e mede), ADR 0093 (o registo de autoridade, pelo hash dos
  pixels) e ADR 0094 (a perda da amostragem e a autoridade da pose, decidida no mesmo dia); a Asset Bible não muda
- Tarefa: [FORJA-08](../backlog/FORJA-08.md)
- Origem: a [auditoria técnica de 27/10](../art/research/2026-10-27-forja-auditoria/README.md), com o pedido do dono:
  *«Elabora uma densa e extensa auditoria na forja, encontre falhas e coisas a melhorar e refinar, depois busque na web
  como fazer isso e aplique»*

## Contexto

A auditoria reproduziu dezasseis falhas sem rede (B01–B16). A maior parte é reparo; quatro mudam o que a Forja entende
por uma imagem, por uma cor ou por um gasto, e ficam aqui. O conector do Gemini entregava os rascunhos do pensamento do
modelo como a imagem paga (B01). O voto da cor de cada célula, em baldes fixos de 16 níveis, dava a célula à cor
minoritária sempre que a maioritária, ruidosa, caía numa fronteira de balde — e 86 das 112 cores da paleta estão a três
níveis de uma (B02). A abertura ignorava a orientação EXIF e o perfil ICC, e o hash dos pixels contava a cor escondida
debaixo do alfa 0, que um editor grava como quer (B06–B08). O teto de gasto lia-se uma vez por processo (B03), e o
registo escrito antes do POST não chegava ao disco com garantia (B09).

## Decisão

1. **Do Gemini entra só a imagem final.** `output_image` («o último bloco de imagem gerado») quando vem; senão, as
   imagens fora dos passos `type: "thought"` e das partes `thought: true`. As que ficam de fora contam-se
   (`thought_images_skipped`).
2. **O voto procura o balde em oito grelhas.** As grelhas de 16 níveis deslocam-se meio balde em cada canal (o
   histograma deslocado médio de Scott, 1985); ganha o balde mais cheio de todas, e no empate a grelha sem
   deslocamento. Se a cor exata mais frequente pesa 35% do balde, é ela; senão, a média em luz linear da vizinhança de
   8 níveis centrada no balde. Uma célula lisa ou de duas cores exatas sai igual a antes.
3. **A imagem lê-se como se vê.** A abertura aplica a orientação EXIF e converte para sRGB um perfil ICC que não é sRGB
   (ImageCms, intenção colorimétrica relativa); um perfil sRGB, ou nenhum, não se toca. O que se fez fica na
   proveniência (`input.opened`).
4. **O hash dos pixels não vê o invisível.** Um pixel de alfa 0 conta como `(0, 0, 0, 0)`. O registo de autoridade e
   as observações (ADR 0093) continuam presos aos pixels; um pixel visível mudado continua a mudar o hash, e uma imagem
   sem cor escondida tem o hash que tinha.
5. **O gasto conta-se no disco, com lock.** Cada conta do teto relê o `budget.json` com um lock exclusivo entre
   processos, e conferir e contar a chamada são um só passo. Os jobs e o teto escrevem-se com troca atómica e `fsync`
   (do ficheiro e da pasta, em POSIX).

## Alternativas consideradas

- **Um voto por agrupamento em OKLab (k-means ou mean-shift por célula).** Resolve a fronteira, mas é quadrático nas
  cores de cada célula, em Python puro, numa prancha de milhares de células. As oito grelhas custam oito passagens.
- **Converter sempre pelo perfil, também o sRGB.** A transformação arredonda: uma cor exata da paleta podia voltar
  uma unidade ao lado.
- **Recusar uma imagem com perfil ICC.** Mandava o agente converter à mão, sem dizer com que intenção.
- **A luminosidade Lr de Ottosson na escolha da cor da paleta.** Acerta o preto ruidoso (O1), mas muda a cor escolhida
  em 7% do espaço sRGB e a ADR 0088 fixa o OKLab: fica como pergunta (Q-290), com a medida nas sondas.
- **Uma dependência de lock (filelock, portalocker).** O `fcntl` e o `msvcrt` da biblioteca padrão chegam (regra 8).

## Consequências

- Nenhuma dependência nova. Módulo novo: `durable.py`. O servidor MCP passa a responder `-32600`/`-32602` com id null,
  a ler e escrever UTF-8 e a dar título e anotações a cada ferramenta; sem `structuredContent`, que nalguns clientes
  esconde do modelo a prévia em imagem.
- **Muda de comportamento:** a imagem do Gemini é a final (antes, o primeiro rascunho); o voto pode escolher outra cor
  numa célula ruidosa perto de uma fronteira; uma foto com orientação abre na orientação certa e uma imagem com perfil
  não sRGB muda de números; `Budget.spend` dá lugar a `Budget.reserve`; uma ferramenta desconhecida no MCP é erro de
  protocolo, não resultado; o contorno global do `forge` fecha só as falhas.
- As provas de 24/10, 25/10 e da fidelidade de 27/10 e a prova da Forja saem iguais, byte a byte; a prova da auditoria
  de fidelidade (ADR 0094) muda a pureza escrita em duas notas de grade recusada (0,36 → 0,35 e 0,58 → 0,60), sem mudar
  a recusa; nenhum hash registado no repositório muda.
- Fica por fazer: o preto perto do `#0B0B0B` (Q-290); a falha de contorno com 85% da borda já a preto (Q-291); progresso
  e cancelamento das ferramentas longas no MCP.
- Se a decisão for revertida: voltar `backends/gemini_images.py`, `resample.py`, `imageops.py`, `equipment.py`,
  `jobstore.py` e `jobs.py` ao commit anterior e tirar `durable.py` com os testes `test_auditoria_ii*.py` — e o
  rascunho volta a ser forjado como a imagem paga.
