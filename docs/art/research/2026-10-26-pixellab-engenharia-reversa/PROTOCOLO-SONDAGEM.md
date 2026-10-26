# Protocolo de sondagem caixa-preta do PixelLab

As hipóteses H07–H12 do [dossiê](DOSSIE.md#matriz), e a parte medível de H02–H05, só se resolvem com
pedidos reais à API oficial. Este protocolo diz quais, quanto custam e o que se decide com cada
resultado — escrito **antes** de gastar, como a [metodologia](METODOLOGIA.md#35-experiências-de-caixa-preta-com-desenho)
pede. O plano máquina é [sondas.json](sondas.json): 8 sondas, 29 chamadas, cerca de US$0,44 pelas
estimativas públicas de 26/10. Estado: **por executar** — falta a chave do PixelLab e o dono aprovar o teto.

## Antes de gastar

1. O dono aprova o teto: número de chamadas e dólares (proposta: `--max-calls 29 --max-usd 1`).
2. `python3 -I contrato.py --previous contrato-2026-10-26.json` sem diferenças nos endpoints usados; se
   houver, rever o plano e o adaptador primeiro.
3. `python3 -m tools.forja plan …` para cada pedido: nenhum erro antes da rede.
4. A chave entra só no ambiente (`PIXELLAB_API_KEY`); nunca em ficheiros, relatórios ou jobs.

## Regras durante

- Cada POST passa pela Forja: o job (`jobs/<id>.json`) é escrito antes de o pedido sair, e uma resposta
  perdida fica `submission_unknown` — não se reenvia (`docs/art/FORJA.md`, "Pedidos pagos").
- Não se enviam pedidos que o contrato já diz recusados só para ver a recusa.
- Saídas em `build/forja/sondas/<id>/`. Nada em `art/`. Nenhuma saída treina ou destila um modelo
  (termos 1.2 e 3.3).
- Guarda-se tudo: imagens, resposta sem a chave, `usage.usd`, tempo de fila (`queue_position`,
  `estimated_wait_seconds`) e de execução.

## As sondas

| ID | Pergunta | Tipo | Pedidos | Decide |
| --- | --- | --- | --- | --- |
| S01 | A mesma seed repete os bytes? (H07) | Invariância | Pixen 64×64, seeds 7,7,7,42,42,42 | Se a Forja pode prometer repetição ou só registar a seed |
| S02 | As saídas vêm nativas no tamanho pedido? (H04, H15) | Funcionalidade mínima | Pixflux, Pixen e Bitforge a 64 e 80 | Se o caminho `grid: native` do plano está certo para os três |
| S03 | A força da imagem inicial é monótona? (H08) | Direcional | Pixflux 80×80 com referência, forças 1, 100, 300, 600, 999 | Que forças usar para ideia, forma e retoque |
| S04 | `color_image` impõe a paleta? (H09) | Direcional | Pixflux 64×64 com e sem a paleta do Empire, duas seeds | Se o acabamento de paleta continua obrigatório |
| S05 | O enum `outline` muda o contorno? (H10) | Direcional | `single color black outline` contra `lineless` | Se vale a pena enviar o campo |
| S06 | O Pro devolve 64, 16 e 4 candidatos a 32, 85 e 86 px? Que metadados trazem? (H02, H03) | Funcionalidade mínima | Três pedidos Pro | Confirma o contrato; metadados de fornecedor seriam evidência forte |
| S07 | O exterior da máscara do Bitforge fica igual? (H11) | Invariância | Máscara branca 12×12 num sprite de teste | Se a recomposição da Forja pode ser opcional (não muda o padrão) |
| S08 | O `reduce-colors` partilha a paleta sem mexer em regiões paradas? (H12) | Invariância | Quatro quadros com a paleta do Empire | Comparação cega com o `quantize` da Forja |

## Depois

1. `python3 -I forense.py` sobre as saídas (com um `fetch.log` local) — a mesma régua das imagens da
   documentação.
2. Uma linha por sonda no `sondas.json` passa de `null` a resultado, com o commit, a data, o custo devolvido
   e a decisão tomada pela regra escrita. Uma sonda que não decidiu nada diz isso.
3. A matriz do dossiê muda de nível só onde a sonda decidiu. Nenhum resultado torna arte aprovada nem
   muda contratos do jogo.

## O que o protocolo não faz

Não mede qualidade artística (isso é a revisão do dono, com a rubrica do relatório mestre §18), não
compara com outros geradores (o piloto do FORJA-02 já o define) e não tenta descobrir pesos, dados ou
código: o desconhecido do dossiê §10 continua desconhecido.
