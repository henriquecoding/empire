# ADR 0089 — A Forja pede uma vez, planeia por gerador e mede o que chega

- Estado: aceite
- Data: 2026-10-23
- Secção do dossiê: §01 e §22 (a unidade gráfica), §58 (os slots)
- Complementa: ADR 0088 (a Forja), ADR 0087 (o elenco V15, usado só para leitura na fatia vertical)
- Tarefa: [FORJA-02](../backlog/FORJA-02.md)
- Origem: a [auditoria de 23/10](../art/research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md) e o
  [pedido de continuidade](../art/research/2026-10-23-pixellab/PROMPT-PARA-CLAUDE.md)

## Contexto

A auditoria do commit `68ed1c8` reproduziu nove falhas sem rede. Quatro tocavam dinheiro e pedidos: um POST de
geração repetido quatro vezes depois de um 503 (F01); o `auto` do PixelLab a pedir 1920×1920 e a largar a referência
(F02); o Gemini a receber uma proporção e uma resolução diferentes das que a extração assumia, com a paleta prometida
no texto e nenhuma imagem anexada (F03); e o polling sem prazo, cancelamento nem retomada (F09). Quatro destruíam arte:
o azul legítimo apagado na edição (F04), pixels de um píxel tirados sem política (F05), saltos e agachamentos
alinhados até à deriva zero (F06) e a direção das tags perdida no Godot (F08). E a validade estrutural servia de
condição de paragem, de modo que uma caminhada de dois quadros iguais passava (F07).

A especificação pública do PixelLab (hash `e322e725…`, igual ao da pesquisa) não documenta idempotência; a do
Gemini não publica a tabela de pixels de saída por proporção.

## Decisão

1. **Um POST pago sai uma vez.** Recusa clara (4xx) é `rejected`; resposta perdida ou 5xx é `submission_unknown` e
   não se reenvia sem decisão explícita. Só consultas (GET, DELETE) se repetem, com espera exponencial, jitter,
   `Retry-After` e prazo. Nenhum cabeçalho de idempotência inventado.
2. **Cada pedido é um job durável** (`<pasta>/jobs/<id>.json`, escrito antes do envio): descritor sem base64 nem
   chaves, hash do pedido, hashes e papéis das imagens, tentativas com tempos, id remoto, custo dito ou `unknown`,
   saídas com hash e tamanho medido. Retomar só consulta; cancelar regista a resposta sem prometer que não houve
   cobrança. O teto (`--max-calls`, `--max-usd`) é da pasta e soma entre corridas.
3. **Um plano por gerador, validado sem rede.** PixelLab no tamanho nativo do contrato (`royal_64` 64×64, `royal_80`
   80×80), com a referência em `init_image` (tamanho exato) e a paleta em `color_image`; animação recusada até os
   endpoints próprios serem ligados. gpt-image com lados livres e imagens por papel em `/images/edits`. Gemini numa
   proporção e resolução suportadas, com a prancha centrada e as margens escritas em pixels lógicos. O prompt só
   promete as imagens que vão anexadas.
4. **O que chega é medido.** A escala só se dá como conhecida quando o fornecedor desenha no tamanho nativo e o
   tamanho recebido o confirma; nos outros casos a grade é detetada e comparada com a pedida (`grid_not_followed`).
5. **Preservar antes de limpar.** A edição usa uma chave ausente do sprite e da paleta, recusa outro tamanho e
   devolve os bytes originais onde a resposta não mudou. A limpeza tem política por tipo (cenário tira pixels soltos e
   tapa furos; personagem, efeito e `free` só os apontam) e caixas protegidas. As pranchas mantêm a origem de cada
   figura na célula e levam só o chão comum ao pivô.
6. **Três respostas que não se confundem.** `contract_valid` mede-se; os indícios de movimento (`motion_checks`)
   pedem revisão; `artistic_approval` é sempre `pendente`. Só um movimento que não existe (todos os quadros iguais)
   obriga a gerar de novo. Repetições de propósito declaram-se (`--hold quadro:ms:razão`, `same_as`).
7. **As tags tocam como foram escritas.** O `SpriteFrames` do Godot recebe a sequência já tocada (`reverse`,
   `pingpong`, `pingpong_reverse`), com a duração de cada quadro; uma direção desconhecida é erro.

## Alternativas consideradas

- **Manter o retry com um cabeçalho de idempotência.** Nenhum dos fornecedores ligados o documenta; inventá-lo daria
  a ilusão de segurança e manteria o risco de cobrança dupla.
- **Uma base de dados (SQLite) para os jobs.** Um ficheiro JSON por job, escrito com troca atómica, chega para um
  utilizador, é legível no repositório de trabalho e não traz dependência.
- **Redimensionar a referência para o tamanho do PixelLab.** Esconderia uma reamostragem; a Forja pede o tamanho
  certo (`forja fit`/`snap` antes).
- **Fixar a tabela de pixels do Gemini de memória.** Não está nas páginas lidas nesta data; estimar e medir é
  honesto e falha visivelmente quando a estimativa erra.

## Consequências

- Nenhuma dependência nova; `make forja` continua a correr a prova e os testes, agora 136, incluindo a ida e volta
  exata dos quadros reais da bailarina (64) e da Sombra (80) pela tira, JSON, `.aseprite` e Godot.
- O `auto` deixa de parar só porque o contrato passou: uma prancha estática não passa, e a aprovação nunca passa
  sozinha.
- O piloto pago ficou definido (referências, casos, teto proposto, comandos) e por executar: não há chaves nesta
  sessão e o teto precisa do dono.
- Se a decisão for revertida: voltar `tools/forja/backends/http.py`, `jobs.py`, `plan.py` e `review.py` ao commit
  `68ed1c8` — e voltam as nove falhas que a auditoria reproduziu.
