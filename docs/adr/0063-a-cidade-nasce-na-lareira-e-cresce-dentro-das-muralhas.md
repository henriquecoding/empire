# ADR 0063 — A cidade nasce na lareira e cresce dentro das muralhas

- **Estado:** aceite no âmbito do pedido do dono de 04/10/2026.
- **Data:** 2026-10-04
- **Tarefa:** `docs/backlog/RG-21.md`.
- **Substitui:** ADR 0060, pontos 3 e 7, quanto às exceções exteriores e à autoria das bancas.

## Problema

A fundação já erguia as ferramentas, mas o arco ficava a +848 px e o martelo a
−2080 px: ambos fora da primeira linha de muralhas (±680 px). As hortas iniciais
dispensavam defesa, e torres, fogueiras e sinos podiam aparecer na frente ainda
não incorporada. Bastava o primeiro muro para oferecer todos os recintos seguintes,
sem relação entre a expansão territorial e o nível da sede.

## Decisão

1. **A lareira é o ponto de fundação.** A Clareira mostra pedra e lenha apagada,
   sem tendas nem bancas. O mesmo pagamento existente da sede funda o Acampamento;
   as duas bancas surgem somente no evento de conclusão. O custo permanece em dados.
   Acender a fundação não concede gratuitamente o efeito de proteção noturna da Q-190.
2. **Ferramentas dentro do primeiro traçado.** O martelo fica a −552 px e o arco a
   +552 px. A largura inteira cabe entre a sede, os canteiros e a face interior da
   primeira muralha. A fundação não levanta ferramentas de outro território nem bancas
   colocadas fora desse traçado. São a única exceção que dispensa uma muralha de pé:
   exigir o muro primeiro impediria formar quem o constrói.
3. **Toda obra interna nova exige recinto concluído.** Hortas, torres, fogueiras,
   sinos e outros serviços usam a política `protected`, além do nível da sede,
   das descobertas e do apoio produtivo já existentes. A área termina na face interior
   da muralha, e não no centro dela. Obras pagas, em curso, erguidas ou em ruína
   continuam acessíveis quando a defesa cai. Acampamentos de recrutamento, passagens
   e edifícios de outros povos conservam a identidade exterior.
4. **Cada nível abre espaço para avançar.** `realm_stages.csv.wall_rings` define as
   linhas possíveis por flanco: Acampamento permite a primeira; Povoado a segunda;
   Vila a terceira. Os estágios superiores conservam as linhas autoradas existentes.
   O próximo marco só aparece quando a linha anterior desse lado está de pé e a sede
   permite essa expansão. Subir a sede não ergue muralhas nem revela edifícios exteriores.
5. **Um canteiro por flanco no arranque.** Os dois canteiros mais externos da primeira
   autoria passam para ±1068 px, no segundo recinto. Os canteiros em ±456 px continuam
   no recinto fundador; as posições libertas recebem as ferramentas. Preserva-se a
   ordem dos slots e todos os ids, níveis, moedas pagas, trabalho, saúde e formação.
   A fogueira oriental passa para +1640 px, no recinto exterior, libertando a folga
   de 24 px entre o segundo canteiro, o galinheiro e a torre alta.
   Ao retomar, a autoria atual reposiciona esses sítios pelo id; não se duplica
   conteúdo nem se reinicia a partida. Nenhum custo foi modificado para satisfazer testes.
6. **O guia explica a expansão.** A lareira anuncia as duas bancas. Uma melhoria que
   libera outra linha informa que cada flanco ganha uma nova frente; os pagamentos
   e a execução das obras continuam separados.

## Dados e validação

A correspondência entre estágio e linhas de expansão é uma proposta reversível de
autoria, registrada na Q-230. Não há tecnologia, economia, dependência ou arte externa nova.
Os recursos são gerados pelo conversor existente; a skill do projeto proíbe editar
`.tres` à mão.

Testes de regressão cobrem: inexistência de bancas antes da fundação, pagamento e
conclusão da lareira, posições sem sobreposição, fechamento de ferramentas exteriores,
expansão independente dos flancos, nível mais alto sem território conquistado,
hortas por recinto, id e progresso após guardar/retomar. A abertura natural inclui
o recrutamento, arco, martelo, muralha e canteiro usando as intenções reais do jogador.
