# 18 — Multijogador · Dois modos, ambos na Fase 8

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O relatório mestre e ADR 0067/0068 definem o contrato atual. Solo funda um reino; Coop partilha um reino; PvP começa com dois reinos independentes. A implementação online continua pendente.

**Cooperativo — um império** — Dois jogadores e monarcas distintos, população e economia do mesmo reino. Apenas P1, criador da sala, confirma a fundação. P2 pode explorar e sugerir um local. A saída de P1 antes de fundar não transfere automaticamente essa permissão. O servidor mantém a partida e permite reconexão ao mesmo PlayerSlot.

P1 começa a Oeste e P2 a Este, cada qual com caravana, tesouro, conhecimento e fundação próprios. A vitória exige soberania total sobre o reino adversário. Captura, transferência de soberania, graça competitiva e desconexão precisam de regras explícitas antes da implementação (Q-236).

| Componente | Contrato | Estado |
| --- | --- | --- |
| Cliente Godot Web/native | Envia intenções identificadas; recebe snapshot e atualizações. Não decide saldo, combate, fundação ou vitória. | Cliente Solo existente; rede por fazer. |
| Servidor dedicado Godot | Autentica jogadores, valida permissões, ordena intenções e simula o mundo. Sobrevive à saída do criador da sala. | Por fazer, RG-25/UN-31. |
| Vercel | Distribui site, painel e export Web; não executa o loop autoritativo da partida. | Site existente. |
| Supabase | Persistência e serviços de apoio, com permissões verificadas no servidor; o painel de decisões já utiliza RLS. | Painel existente; integração de partidas por fazer. |
| Protótipo local | Testa permissões e isolamento por reino; não conclui aceitação online. | UN-29/UN-30 por fazer. |


> **Prioridade e aceitação**
>
> Estas regras substituem a proposta anterior de titular/delegado, vitória alternativa por sobrevivência e autoridade do host-cliente. Online só está concluído com dois clientes, servidor dedicado, snapshots, reconexão e comandos idempotentes testados sob latência e perda. Transporte e hospedagem do servidor são decisões pendentes, não uma dependência já instalada.
