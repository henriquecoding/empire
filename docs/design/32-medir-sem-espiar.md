# 32 — Telemetria · novo · Medir sem espiar

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Vais ter dez playtesters, não dez mil. Isso significa que os números têm de responder a perguntas que a observação não responde — e que a observação continua a valer mais do que os números.

## Os doze eventos, e o que cada um responde

| Evento | Propriedades | A pergunta que responde |
| --- | --- | --- |
| session_start | build, plataforma, idioma, dispositivo | Quem está a jogar e em quê |
| session_end | duração, dia atingido, motivo de saída | Onde é que as pessoas desistem |
| first_coin_dropped | segundos desde o início | Perceberam o Verbo 1? Alvo: < 40 s |
| first_wall_built | segundos, dia | Perceberam construção? Alvo: < 4 min |
| underground_discovered | segundos, dia, como (passagem/ruína) | Encontraram a tua maior diferenciação? Alvo: < 14 min |
| night_survived | dia, mortes, muro caiu, tropas restantes | A curva de dificuldade está certa? |
| night_lost | dia, composição da defesa, criatura que rompeu | Qual criatura mata mais gente e porquê |
| economy_snapshot | dia, tesouro, rendimento, sorvedouros, ganância | O dia da asfixia real vs. o modelo (§06) |
| fortress_attacked | dia, resultado, rei morto ou poupado | Quantos escolhem cada epílogo |
| class_switched | de, para, dia | Que classes ninguém usa — candidatas a corte |
| craft_evolved | ofício, dias que demorou, morreu antes | O dilema do artesão está calibrado? |
| run_ended | dia final, causa, sementes acumuladas | Quanto dura uma partida |


> **Privacidade — decide antes de escreveres a primeira linha**
>
> Sem dados pessoais. Um ID aleatório gerado localmente, sem IP, sem nome, sem perfil de Steam. Consentimento explícito no primeiro arranque, desligado por omissão na versão pública. É a decisão certa, e para ti, em Portugal, também é a única compatível com o RGPD sem trabalho de conformidade. Durante os playtests fechados, com testers que sabem, podes ser mais generoso.

## O protocolo de playtest que funciona com dez pessoas

1. Cinco pessoas, uma hora, sem ti a falarA regra mais difícil e a mais importante: não explicas nada. Se tiveres de explicar, é um bug de design, e acabaste de o encontrar. Anota o minuto exato de cada confusão.

## Grava o ecrã, não a cara

Precisas de ver onde eles olham e o que tentam clicar. OBS local, ficheiro apagado depois. É mais barato e mais útil do que qualquer plataforma de analytics.

## Duas perguntas no fim, sempre as mesmas

"O que é que estavas a tentar fazer quando ficaste preso?" e "Descreve-me o jogo como se estivesses a falar com um amigo." A segunda diz-te se o teu pitch funciona — e é o texto da tua página de Steam.

## Repete com os mesmos, três meses depois

Retenção é a única métrica que prevê análises positivas. Se eles voltarem por vontade própria, tens jogo.
