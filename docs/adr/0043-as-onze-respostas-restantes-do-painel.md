# ADR 0043 — As onze respostas restantes do painel

- **Estado:** aceite, em validação (01/10/2026).
- **Contexto:** Q-170, 171, 172, 174, 175, 176, 177, 178, 179, 180 e 182 foram
  aprovadas a 30/09/2026. As palavras do dono ficam em `docs/QUESTIONS.md`.

## Decisão

| Resposta | Comportamento |
|---|---|
| Q-170 | Muralha própria além do acampamento ou Amargueiro próximo abatido acaba com ele. No sítio fica uma casa construível, até três cidadãos à espera, mais caros. |
| Q-171 | O decay mantém as obras escolhidas; as restantes próprias ficam em alicerce com nível, caminho e variante. Reerguem-se por uma fração do investido, com quaisquer mãos próprias presentes. |
| Q-172 | Primavera, verão, outono e inverno. Canteiros param e a caça abranda no inverno; pesca, galinhas e reservas de grão permitem preparar-se e sobreviver. Só produção nova entra na reserva, antes da conversão. |
| Q-174 | Cada fortaleza e acampamento mercenário tem casa, oficina, defesas, trabalhadores, construtor e guarnição; tesouro, produção, soldo, flechas, reposição e reparação locais. A Podridão também os ataca. |
| Q-175 | Kits de segmentos e assuntos próprios dos oito povos, casas/oficinas/defesas distintas. O povo do pântano chama-se Bruma, nome de trabalho ajustável. Paul nos saves migra para Bruma; Paul do Boquilobo continua a ser o lugar real. |
| Q-176 | Masmorras com tesouro, guarda ou relíquia, com prémio normal, duplo ou triplo. Sorteio por sítio, sem gastar o fluxo de simulação. Loot persiste e nunca se repõe ao carregar; o guarda permanece à alvorada. |
| Q-177 | Mercenários cobram mesmo sob o limiar gratuito das tropas regulares e desertam primeiro. Depois de três contratados o acampamento esvazia-se e as obras ficam em ruína. |
| Q-178 | Só as classes viajam. Na bifurcação ou fortaleza conquistada, de dia, viajam a um reino vassalo com defesas de pé. O rei fica em casa; a guarnição local combate de noite; a viagem volta a abrir de dia. |
| Q-179 | Fissuras no chão em um lado ou dois, sorteados por noite. Conserva-se a massa total e o limiar existente do dia 12 para dois lados; primeiras dez noites mantêm a curva e sequência de antes. |
| Q-180 | O legado guarda semente e todo o mapa gerado. Ao recomeçar, as terras reveladas reaparecem desabitadas, sem novos recrutas nem loot. Obras próprias dinâmicas são remapeadas por tipo e posição. |
| Q-182 | Dither local à volta de criaturas subterrâneas perto de boca aberta; bocas visitadas permanecem localmente abertas. Não abre o subsolo inteiro à superfície. |

## Dados e compatibilidade

Save **v6**: partes novas entram vazias e identificadores antigos do pântano são
convertidos recursivamente, incluindo colunas e chaves de dicionário. Protótipos
dinâmicos restauram-se por id antes do estado; serras do Amargueiro têm tratamento
próprio e não são procuradas no Registry de edifícios. Duas serras no mesmo x
continuam distintas. A reparação habitual continua a pedir construtor; alicerces
não o pedem, para não bloquear uma Casa de Treino caída.

Os números novos são propostas em `_proposed`, não aprovações atribuídas ao dono:
16 dias por estação; caça de inverno 35%; reserva 25% do grão novo, teto 64,
libertação 4 por dia; soldo mercenário 1; recompensas 3–6, tesouro 60%, relíquia
15%, prémio duplo 15% e triplo 5%, relíquia 1 Semente; dois lados 50% depois do
limiar existente; aviso subterrâneo 1280 px, boca visitada 80, criatura 160;
tesouro local inicial 30, guarnição 3 mais unidade única, dois cidadãos e um
construtor, soldo regular 0,3, substituição 3; massa local 50%, até seis criaturas.
Edifícios locais: custo 8, vida 64, trabalho 16 s, largura 80; casa de cidadãos
largura 96. Todos ajustáveis nas tabelas. O teto de três cidadãos e as três
contratações são números da proposta aprovada.

## Integração e verificação

Esta ADR substitui a regra «uma resposta por commit» da ADR 0041 neste lote:
território, autoria dinâmica, ids, legado e migração são dependências comuns.
Checkpoints na branch preservam o trabalho; revisão/CI e merge formam um lote
coerente. Só depois de integrado e publicado se marca aplicada no painel.

Testes de regras escritas antes da implementação e testes de integração cobrem
reservas fracionárias, soldo, remapeamento, duplicação de serras/loot, mapa
abandonado, tesouro nativo, viagem sem mover o rei e janelas locais. Suite completa,
portões, dados, vistoria e exportação são obrigatórios antes do merge.
