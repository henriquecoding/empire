# Forja — reparos da auditoria, fatia vertical e piloto (23/10/2026)

Continuação pedida por Henrique com a [auditoria](../2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md), o
[relatório mestre](../2026-10-23-pixellab/RELATORIO-MESTRE.md) e o
[pedido de continuidade](../2026-10-23-pixellab/PROMPT-PARA-CLAUDE.md). A Forja do PR #117 foi corrigida no próprio
`tools/forja/`, sem ferramenta paralela. Decisão: [ADR 0089](../../../adr/0089-a-forja-pede-uma-vez-e-mede.md).
Tarefa: [FORJA-02](../../../backlog/FORJA-02.md). Guia atualizado: [FORJA.md](../../FORJA.md).

**Em resumo:** as nove falhas reproduzidas pela auditoria estão corrigidas, cada uma com testes que afirmam o
comportamento novo. A fatia vertical com `royal_64` (bailarina) e `royal_80` (Sombra) corre sem rede, da referência
à ida e volta exata no Godot. A geração real e o piloto **não foram executados**: não há chaves de gerador nesta
sessão e o teto de gasto precisa do dono. Nenhum resultado de geração foi inventado. Nenhuma arte nova, nenhuma
aprovação.

## Fatos, inferências e escolhas

| Tipo | Exemplos neste trabalho |
| --- | --- |
| Fato documentado | Limites do PixelLab lidos na especificação pública (hash `e322e725…`, o mesmo da pesquisa): pixflux até 400×400, pixen múltiplos de 4 até 512×512, `init_image`, `color_image`, `DELETE` de job, 529 = limite de taxa, nenhuma idempotência. Proporções, resoluções `1K/2K/4K` e limites de referência do Gemini nas páginas de 23/10 |
| Lacuna registada | A tabela de pixels de saída do Gemini por proporção não foi achada; a Forja estima e mede. Como os modelos do PixelLab desenham por dentro não está publicado |
| Escolha nossa | Um ficheiro JSON por job; a identidade no PixelLab via `init_image` (o `create-image` não tem campo de identidade); tamanho do Gemini com ≥ 8 px por pixel lógico; política de limpeza por tipo; alinhamento `preserve` com grelha |

## Antes e depois, por achado

Antes: [observacoes-antes.json](observacoes-antes.json) (o script da auditoria no commit `4b18494`, igual ao
`68ed1c8` nos módulos da Forja). Depois: [observacoes-depois.json](observacoes-depois.json)
([sondas_depois.py](sondas_depois.py), os mesmos cenários com a API nova). O script da auditoria continua como
registo; depois dos reparos ele para no F02, porque o pedido que sondava (referência de 64×64 num quadro de 96×96)
passou a ser recusado antes de qualquer rede.

| ID | Antes | Depois | Testes que o afirmam |
| --- | --- | --- | --- |
| F01 | 4 POSTs depois de um 503 | 1 POST; 503 e tempo esgotado ficam `unknown`; o job relido não volta a pedir (0 POSTs) | `test_backends.SendTest`, `test_jobs.SubmissionTest` |
| F02 | 1920×1920 ao pixflux; referência largada | `royal_64` → 64×64, `royal_80` → 80×80, `character_s2` → 96×96; referência no `init_image` com hash no plano; tamanho, modelo e animação inválidos falham sem rede | `test_plan.PixelLabPlanTest` |
| F03 | escala 5 assumida, 3:2 a 1K pedido, paleta prometida e 0 imagens | proporção e resolução suportadas, margens escritas, prompt só promete o anexado (1 imagem = 1 promessa), grade medida (`grid_not_followed`) | `test_plan.GeminiPlanTest`, `OpenAIPlanTest` |
| F04 | 64 pixels azuis apagados num eco | eco devolve o sprite byte a byte; chave fora do sprite e da paleta; tamanho errado é erro | `test_preserve.InpaintTest` |
| F05 | `noise=0` tirava o pixel solto e tapava o furo | `free`, personagem e efeito mantêm-nos como candidatos; o cenário limpa; caixas protegidas | `test_preserve.CleanupPolicyTest` |
| F06 | salto de 4 px achatado (pés iguais) | pés a 17 e 13: o salto fica; passada sem abanar o tronco; agachar não cresce; flor com raiz fixa | `test_preserve.OffsetTest` |
| F07 | `walk:2` de quadros iguais dava `ok=true` | `ok=false`, `needs_regeneration`, `static_tag`; holds declarados aceites; repetidos escondidos, saltos e partes perdidas apontados | `test_preserve.ReviewTest` |
| F08 | `reverse` saía 0,1,2 | 2,1,0 com durações 3,2,1; pingpong; direção desconhecida é erro; conferido no Godot 4.7.2 | `test_preserve.GodotOrderTest` |
| F09 | polling sem fim | prazo e limite (7 consultas em 96 s de relógio falso); retomada só por GET; cancelamento; concluído sem imagens é erro | `test_jobs.PollingTest` |

Também apareceu um defeito antigo: a deteção de grade levantava `StopIteration` em recortes minúsculos (um rebento
de 1 px). Corrigido em `grid._first_peak`.

## Fatia vertical

[fatia_vertical.py](fatia_vertical.py) → [fatia/fatia-vertical.json](fatia/fatia-vertical.json), e
`test_fatia.py` no CI.

| Passo | Estado | Evidência |
| --- | --- | --- |
| Referência autorizada | Feito | Quadro 0 (`idle_right`) da bailarina e da Sombra do V15, com hash; integrados pela ADR 0087, design da dupla aceito em 19/10, **animação sem aprovação artística** |
| Plano validado | Feito, sem rede | 3 geradores × 2 tamanhos × (parado, `walk:8`): 10 planos válidos; a prancha no PixelLab é recusada com o motivo |
| Geração real | **Bloqueada** | Sem `OPENAI_API_KEY`, `GEMINI_API_KEY`/`GOOGLE_API_KEY` nem `PIXELLAB_API_KEY`/`PIXELLAB_SECRET`/`PIXELLAB_API_TOKEN`; teto por aprovar |
| Revisão | Feita sobre os quadros V15 existentes (não é geração nova) | 48 e 56 quadros; 8 e 9 repetições declaradas reconhecidas; 0 duplicados escondidos; nenhuma tag estática |
| Exportação | Feita | Tira, JSON do Aseprite, `.aseprite`, `SpriteFrames` |
| Ida e volta | Feita | Cada quadro igual byte a byte pela tira/JSON e pelo `.aseprite` relido; ordem, durações e loops iguais no Godot 4.7.2 |

Medidas (canvas, área opaca e cabeça são medidas distintas): bailarina — canvas 64×64, pivô (32,62), caixa opaca do
idle 22×36; Sombra — canvas 80×80, pivô (40,78), caixa opaca do idle 55×60. A cabeça não é localizada
automaticamente: medida humana pendente. Escala no mundo: a do jogo (ADR 0087).

Prova a 1× e 2× (fundo claro e escuro) e em movimento, dos quadros V15:
[bailarina 1×](fatia/dancarina-idle-walk-1x.png), [2×](fatia/dancarina-idle-walk-2x.png),
[andar](fatia/dancarina-walk@2x.gif); [Sombra 1×](fatia/sombra-idle-walk-1x.png),
[2×](fatia/sombra-idle-walk-2x.png), [andar](fatia/sombra-walk@2x.gif).

Estados, separados: **design aceito** — a prancha de 19/10, não alterada; **animação revista** — nada novo foi
revisto por pessoa nesta entrega; **integração testada** — a exportação da Forja com quadros reais, no ficheiro e no
motor. A Forja não escreveu em `art/`.

## Piloto

[piloto.json](piloto.json): estado `nao_executado_bloqueado`. Definido antes de qualquer gasto: referências (com
hashes), quatro casos (bailarina e Sombra paradas nos três geradores; caminhada de 8 quadros em gpt-image e
Gemini), teto proposto (24 chamadas, US$10 de custo conhecido, 8 por gerador — por aprovar), comandos exatos e a
ficha de revisão humana (rubrica de 1 a 5, minutos de retrabalho, aceite com ou sem edição). Custo conhecido: US$0.
Tempo humano: nenhum medido, porque nada foi gerado.

## Falhas e limites abertos

- O comportamento real dos três geradores continua por medir (tamanho recebido, aderência à grade, rosto, mãos).
- A tabela de pixels do Gemini é uma estimativa; o desvio fica registado em cada job.
- Animação no PixelLab (`animate-with-text-v3` e afins) não está ligada; o plano recusa-a em vez de a fingir.
- Os indícios de movimento (sobreposição, área, peças) são heurísticas sem calibração em gerações reais; não decidem.
- Um gerador geral desenha rostos abaixo da grade; a Forja aponta, não recupera (ver a pesquisa da Forja).
- O `.aseprite` não foi aberto no aplicativo Aseprite.
- Ainda não há backend licenciado e substituível próprio (ciclos E/F do relatório mestre); qualquer modelo novo
  precisa de ADR de dependência e licença por componente.

## Próximo experimento

Definido pelas falhas acima: com chaves e teto aprovado, correr o piloto como está e medir, por saída, tamanho
recebido, desvio da grade, retenção do rosto e da silhueta contra a referência (rubrica humana a 1× e 2×) e minutos
de retrabalho. Se o PixelLab nativo preservar melhor o rosto do que gpt-image/Gemini com recuperação de grade, ligar
os endpoints de animação dele com contagem de quadros e quadro de referência explícitos; se não, testar `inpaint`
na caixa do rosto como correção localizada. Só depois disso faz sentido avaliar um modelo licenciado próprio.

## Repetir

```bash
python3 -m unittest discover -s tools/forja/tests -t .          # 136 testes (GODOT=<motor> para os do Godot)
python3 -m tools.forja prova                                      # 11/11
python3 docs/art/research/2026-10-23-pixellab/reproduce_forja_findings.py   # para no F02 (recusa local)
python3 docs/art/research/2026-10-23-forja-reparos/sondas_depois.py
GODOT=<motor> python3 docs/art/research/2026-10-23-forja-reparos/fatia_vertical.py
```
