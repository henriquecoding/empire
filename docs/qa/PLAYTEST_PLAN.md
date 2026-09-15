# Plano de playtest

> O protocolo está no §32 e é curto de propósito: **cinco pessoas, uma hora, sem ti a falar; grava-se o ecrã, não
> a cara; duas perguntas no fim, sempre as mesmas; repete-se com as mesmas pessoas três meses depois.** Este plano
> diz **quando** se testa, **o que** se pergunta em cada ronda, **que números** se recolhem e **que decisão** cada
> resultado obriga a tomar.
>
> Formulário: [`PLAYTEST_FORM.md`](PLAYTEST_FORM.md) · Telemetria: §32 · Portões: §33, §37

## 1 · As rondas

| Ronda | Quando | Build | Quem | A pergunta que decide |
|---|---|---|---|---|
| R0 — tu | todas as sextas (§28) | a da semana | tu, 30 min | o que aborrece? (uma linha no diário) |
| R1 — greybox | fim da Fase 1 (mês 4) | 10 dias em blocos de cor, personagens reais | 3 amigos | sobreviver 10 dias é possível e não é trivial? |
| **R2 — o portão** | **fim da Fase 2 (mês 7)** | fatia vertical: 1 povo, 1 bioma, 1 fortaleza | **5 estranhos** — marca-os já (§38) | **querem jogar o dia 11?** |
| R3 — segunda camada | fim da Fase 3 | subsolo, segredos | 5 (3 novos + 2 da R2) | o minuto 10 do §25 funciona com estranhos? |
| R4 — demo | Fase 4–5 | demo pública | 10 + telemetria opt-in | a demo converte em *wishlist*? |
| R5 — retenção | 3 meses depois da R2 | a build mais recente | **os mesmos 5 da R2** | voltam por vontade própria? |

## 2 · As perguntas da R2 — o portão da Fase 2

As do relatório mestre, cada uma com a forma de lhe responder **sem perguntar diretamente** (perguntar "percebeste
X?" ensina X):

| Pergunta | Como se responde | Sinal de alarme |
|---|---|---|
| O jogador entende o que fazer? | minuto da primeira moeda largada | `first_coin_dropped` > 40 s (§25) |
| Sabe porque morreu? | pergunta 1 do fim: "o que estavas a tentar fazer quando ficaste preso?" | a resposta não menciona a Podridão nem a muralha |
| Entende como gastar moedas? | minuto da primeira muralha; moedas que ficaram por gastar | `first_wall_built` > 4 min (§25) |
| Entende quando a noite começa? | onde está no crepúsculo — a recolher ou lá fora? | apanhado fora das muralhas na 1.ª noite |
| Entende o perigo da Podridão? | olha para o horizonte durante o crepúsculo (gravação) | nunca olha até ela chegar |
| Consegue planear? | decisões antes da noite (constrói torre antes do dia 4?) | só reage, nunca antecipa |
| Fica repetitivo? | tempo parado; minuto em que deixa de explorar | > 30% do tempo parado a partir do dia 6 |
| **Quer jogar o dia 11?** | no fim do dia 10, **não dizes nada** e esperas | ninguém continua sozinho |
| Lembra-se das unidades? | pergunta 2: "descreve-me o jogo como se falasses com um amigo" | não nomeia nenhuma personagem |
| Há uma estratégia dominante? | composição de exército e edifícios, comparada entre as 5 | 4 em 5 fizeram a mesma coisa e ganharam |

## 3 · As métricas

Recolhidas pela telemetria do §32 (opt-in, sem dados pessoais) ou à mão, da gravação:

| Métrica | Fonte | Alvo / leitura |
|---|---|---|
| Tempo até à primeira construção | `first_wall_built` | < 4 min (§25) |
| Tempo até à primeira tropa | `first_coin_dropped` + recrutamento | < 1 min |
| Tempo até ao subsolo | `underground_discovered` | < 14 min; **> 20 min de mediana = a passagem está mal sinalizada** (§25) |
| Moedas perdidas | `unit_died` com moedas + saque | tendência, não alvo |
| Dia da primeira morte | `night_survived` (mortes) | noite 1 sem mortes (§31) |
| Dia médio de derrota | `night_lost`, `run_ended` | perto do dia de asfixia do modelo (9–14, §06) |
| Criatura que mais mata | `night_lost` (criatura que rompeu) | nenhuma criatura acima de 50% das derrotas |
| Número de edifícios | `economy_snapshot` | — |
| Composição do exército | `economy_snapshot`, gravação | variedade entre jogadores |
| Dano recebido · causado | registo de eventos (§43: 600 últimos) | — |
| Recursos acumulados | `economy_snapshot` | nunca "rico demais" (§02) |
| Decisões por minuto | gravação: moedas largadas + assumir + roda | cai depois do dia 6? = repetição |
| Tempo parado | gravação | < 30% |
| Sessões abandonadas | `session_end` (motivo) | ninguém sai antes do dia 3 |
| Duração da sessão | `session_start` → `session_end` | a hora inteira |

## 4 · Regras de sala

1. **Não explicas nada.** Se tiveres de explicar, é um bug de design e acabaste de o encontrar — anota o minuto (§32).
2. Grava o ecrã (OBS, local); apaga o ficheiro depois. Não gravas caras.
3. Consentimento escrito para a gravação e para a telemetria da sessão (formulário, parte A).
4. As duas perguntas no fim, sempre as mesmas e pela mesma ordem (§32).
5. Uma build, uma semente: toda a gente joga o **mesmo mundo** (`seed` fixa) — é o que torna as sessões comparáveis.
   A semente está visível na pausa (§42).

## 5 · O que cada resultado obriga a decidir

| Resultado da R2 | Decisão (§33, §37) |
|---|---|
| Ninguém quer o dia 11 | **Não produzir os outros povos.** Voltar ao §06 e ao §07 e mudar números até querer — até dois meses (§33) |
| Querem o dia 11, mas há estratégia dominante | afinar custos e o dia de asfixia; nova R2 com 3 pessoas |
| Não percebem a noite | som do crepúsculo e mancha: é problema de apresentação, não de design |
| Não encontram o subsolo | sinalização da passagem (§25) antes de mais conteúdo |
| Tudo verde | avançar para a Fase 3 |

Depois de cada ronda: um ficheiro `docs/qa/playtests/AAAA-MM-DD-rN.md` com as fichas, as métricas e a decisão
tomada — e uma linha no registo de risco se a decisão mexer num portão.
