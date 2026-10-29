# ADR 0099 — A Forja conserva o elenco escolhido

- Estado: aceite para a integração dos conceitos pedida pelo dono
- Data: 2026-10-29
- Tarefa: [FORJA-13](../backlog/FORJA-13.md)
- Complementa: ADR 0093, 0094, 0096 e 0097
- Origem: Henrique pediu integrar estes conceitos e os aprovados no chat anterior,
  conservar a estrutura dos desenhos e aumentar a diversidade. O alquimista conserva
  o nariz longo original e os traços asiáticos. O seu escudeiro deve ter função
  compatível com a alquimia.

## Decisão

O catálogo `tools/forja/cast.json` (`forja.cast/1`) resolve um id ou alias exato para
um contrato de identidade, a pose, o par, a função visual e a decisão do dono. Os
originais ficam em `docs/art/concepts/2026-10-29-elenco/images/`, sem redução,
quantização ou redesenho. Cada contrato `forja.fidelity/1` prende os bytes do
original, o recorte, a tela de destino, as invariantes e a observação visual.

`forja elenco` lista o catálogo. Com `--character` e `--out`, prepara o plano e o
recorte anexado pela infraestrutura de `plan.make`, sem rede. `prompt`, `plan` e
`auto` também resolvem `--character` no catálogo quando não recebem `--fidelity`;
um contrato explícito continua a ter precedência. Um nome desconhecido dá erro.
O comando é exposto por MCP como `forja_elenco`.

As novas soberanas e soberanos usam `royal_80`; os seus escudeiros, `royal_64`.
A inferência de papel reconhece também `imperatriz`, `empress` e `escudeira`.
Os demais conceitos têm o seu destino explícito no contrato, sem alterar os
contratos raster globais nem os dados de balanceamento do jogo.

O escudeiro do alquimista oferece a próxima poção ao imperador e leva os frascos
e ingredientes numa bolsa compacta. O gesto de entrega substitui a caixa pesada
e a pinça, que não comunicavam a ajuda. Conserva luvas simples e avental curto.
A preparação e entrega das doses são uma proposta visual, não uma habilidade
de simulação implementada nem uma decisão sobre cura, dano, consumo ou recarga.
O frasco que entrega tem o mesmo molde e tamanho absoluto do frasco do imperador;
a tela menor do escudeiro não reduz o objeto. As medidas partilhadas na grade nativa
continuam por fechar no mestre de produção. A expressão é adulta e cómica, com
sobrancelhas assimétricas, olhar cético e meio sorriso.
O camponês da Horta é humano e segura o nabo: não nasce vegetação do seu corpo.
O escudeiro real anteriormente definido conserva a sua identidade.

## Estado e limites

A aprovação de um conceito não aprova um sprite nativo, um ciclo de animação ou
uma integração Godot. O registo de referências continua em estado `concept`.
O catálogo regista separadamente `accepted` e `owner_requested_revision`, com
autor, data e evidência. A revisão do rosto do alquimista e do equipamento do
escudeiro é a execução do pedido do dono, não uma aprovação inventada da nova
imagem exata. Um resultado gerado continua `adaptation_in_review` até revisto.

Sem novas dependências; sem escrita em `art/`, `audio/`, `src/` ou `data/`.
