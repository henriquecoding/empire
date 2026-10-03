# ADR 0060 — O reino cresce pelo território e pela gente

- **Estado:** aceite no âmbito do pedido do dono de 03/10/2026; ajustes novos de balanceamento são reversíveis e ficam em `_proposed`.
- **Data:** 2026-10-03
- **Substitui:** ADR 0059, pontos 2 e 3, quanto a obras não listadas e população inicial; Q-110 e Q-221 quanto aos servos da chegada.
- **Tarefa:** `docs/backlog/RG-19.md`.

## Problema

A escada da sede fechava pagamentos, mas o mundo continuava a mostrar todos os edifícios futuros.
Uma obra não listada abria por omissão no Acampamento. A chegada entregava trabalhadores próprios,
um construtor e combatentes neutros dispersos: o recrutamento e a expansão não construíam o reino.

O dono pediu uma progressão mais elaborada, inspirada em Kingdom, arqueiros em base 64×64,
e esclareceu: dois vagabundos próximos para recrutar; os demais devem ser encontrados em acampamentos.

## Decisão

1. **Três condições para um sítio novo:** estágio da sede, posição na expansão e apoio produtivo.
   `realm_stages.csv` continua a definir os estágios. `realm_sites.csv` define colocação, nível de
   defesa e fontes alternativas de apoio. Estátuas, descobertas, conquistas e Lenho continuam a valer.
   Um tipo não listado fica fechado; cadastrar conteúdo passa a exigir uma decisão explícita.
2. **O convite só aparece quando pode ser construído.** `RealmGrowth.visible` serve o desenho,
   o contexto e o destino da moeda. Um sítio futuro invisível não captura uma moeda de recrutamento
   nem começa automaticamente quando se desbloqueia depois. Ruínas, obras pagas, em curso e herdadas
   continuam visíveis. O jogador continua a poder reconstruir o que perdeu.
3. **Expansão por flanco.** Só a próxima muralha vazia de cada lado se oferece. Serviços internos
   exigem que a largura inteira caiba atrás de uma muralha própria de pé; torres e apoios de fronteira
   podem avançar até ao próximo marco, depois de existir uma frente. O núcleo, uma torre ou o muro de
   uma comunidade vizinha não reivindicam terreno. As primeiras hortas de cada lado são a exceção
   de arranque, para não bloquear a economia atrás de uma obra que ela própria precisa financiar.
4. **Produção dá propósito aos serviços.** Cozinha pede alguma fonte de alimento, celeiro pede canteiro,
   salga pede pesca, cercado pede criação, serraria pede madeira, fundição pede minério e forja pede treino.
   Os níveis mínimos de defesa e estes vínculos ficam em dados, separados da geometria.
5. **População inicial:** dois vagabundos neutros junto da Clareira, nenhum trabalhador ou construtor
   próprio, nenhum arqueiro ou lanceiro solto pré-formado. Os outros vagabundos são dos acampamentos
   existentes; a reposição e a geração de acampamentos pelo mundo continuam a funcionar. A companhia
   intrínseca do perfil do monarca continua a ser companhia, excluída da contagem de tropas.
6. **Ferramentas permitem a abertura.** Fundar ergue as bancas de arco e martelo, sem criar pessoas.
   Primeiro recruta-se; depois compra-se a ferramenta para formar o ofício. A banca do martelo forma
   um primeiro construtor por 3 moedas, sem espera de um dia, e só enquanto não houver construtor vivo.
   A Casa de Treino continua a formar os seguintes pelo contrato anterior. Evita-se dependência circular
   entre reparar a primeira defesa, obter um construtor e construir a própria Casa de Treino.
7. **Autoria compatível:** preservam-se a ordem e os ids de todos os sítios anteriores. A banca do martelo
   e o último par de muralhas são acrescentados no final. Esse recinto permite proteger os serviços
   que estavam para lá do segundo par. Não se apaga nem se reposiciona uma obra de um save existente.
8. **Arqueiro 64×64:** o dado visual `sprite_base_px=64` dirige a reexportação da Huntress temporária.
   O corpo em repouso ocupa 64 px de altura dentro da base; armas, movimento e morte conservam um
   canvas comum maior para não cortar frames. Todos usam os mesmos pés, Nearest e desenho nativo.
   Não se altera `scale_tier`, massa, alcance, colisão, dano ou a arte original do dono.

## Pesquisa e limites

O relatório `docs/recovery/PROGRESSAO-TERRITORIO-2026-10-03.md` identifica fontes e separa as
regras observadas em Kingdom das decisões para Empire. Não se copiam custos, cronogramas por ilha
ou toda a cadeia tecnológica de Kingdom. Os números da sede da ADR 0059 continuam propostas;
os níveis mínimos de defesa e o martelo fundador são novas propostas registradas na Q-227.

Não há dependência nova de runtime. A exportação usa Pillow, já usado pelo mesmo exporter.
O formato de save permanece v8: slots anteriores conservam identidade; populações salvas
não são apagadas, recriadas ou convertidas para a abertura nova.
