# ADR 0065 — A Última Carroça

- **Estado:** aceite como protótipo reversível solicitado pelo dono em 04/10/2026.
- **Tarefa:** `docs/backlog/RG-22.md`.
- **Fonte:** relatório aprofundado «Abertura de Empire: como sair da sombra de Kingdom» e respostas atuais do painel.
- **Substitui:** gesto pago de fundação das ADR 0059/0064; companhia inicial da ADR 0052.
- **Conserva:** escada de sede, moedas físicas, muralhas por recinto, três monarcas e campanha herdada.

## Decisão

Implementar a abertura recomendada, **A Última Carroça**. As outras três aberturas do
relatório são alternativas de projeto, não requisitos cumulativos. A aplicação cobre
a ordem dos verbos, pessoas, economia, ecologia, consequência, progressão, descoberta,
tutorial e medição; não se limita à primeira imagem ou ao estandarte.

1. Depois de escolher o perfil, o monarca já se move na chegada. Três vagabundos
   próximos marcham para a clareira; nenhum construtor ou companheiro pertence ao rei.
   Uma árvore marcada pela Podridão cabe na primeira vista.
2. Dois estandartes autorizam a fundação sem pagamento. **Estrada** mantém o núcleo;
   **Bosque** aproxima a sede e a passagem ocidental dos mantimentos, mas a primeira
   muralha passa a incorporar o habitat do coelho e fecha seu respawn. Os habitats,
   mantimentos e cicatriz permanecem no terreno. O relógio diário começa na escolha;
   o tempo observado pelo playtest começa no controle do monarca.
3. A reserva existente continua sendo oito moedas. Cinco ficam na carroça fechada e
   três nos mantimentos expostos. Abrir a carroça ou resgatar a carga não cria dinheiro.
   O andaime gratuito da fundação precisa de presença; depois abre arco, martelo e
   posto da companhia. Os serviços em ±612 px deixam 24 px livres para as obras vizinhas.
4. Um vagabundo contratado recebe, junto à carroça, coleta ou reconhecimento pelo
   Verbo 2; junto aos mantimentos, recebe resgate. Ele caminha e trabalha no local.
   Enquanto atribuído, não trabalha simultaneamente em obras. A coleta dá renda
   alternativa à caça, com limite diário em dados. O martelo continua formando o
   construtor; a banca passa a custar três moedas, conforme Q-227.
5. À tarde, os mantimentos escurecem e a coleta exposta para antes das criaturas.
   Na primeira noite a frente ocidental alcança essa carga: resgate, luz ou muralha
   podem salvá-la. O rasto sem proteção perde a carga e deixa raízes persistentes.
   A alvorada conserva a perda, acrescenta a fita do estandarte e registra consolidação.
6. Riqueza continua necessária para subir a sede, mas cada estágio pede feitos
   explícitos: noite, renda, população, produção, recinto ou descoberta do subsolo.
   Saúde e defesa sobem juntas. A casa do herdeiro só abre na Fortaleza. **Capital**
   continua posterior à rede territorial; não é acrescentada como melhoria de vida.
7. O subsolo próprio começa pequeno, com baú vazio. O canteiro de escavação é um
   serviço de superfície: pagamento, construtor que chega e trabalho alargam a sala,
   um degrau por estágio da sede. Guardar e retirar moedas conserva riqueza; invasores
   no baú podem roubá-la. Baús estrangeiros recebem parte do tesouro já existente do
   reino, uma única vez; não geram moeda ao reentrar.
8. A companhia exige pessoa contratada e sete moedas no posto. A mesma pessoa chega
   e assume o perfil correspondente. Vitórias distintas com monarca e companhia vivos,
   próximos e na mesma faixa fazem ambos evoluir; pagamento na sede não substitui as
   batalhas. Saves antigos conservam companhia e evolução já obtidas.
9. Reparar, mesmo de pé ou na alvorada, exige construtor presente. Reparação de pé
   é mais rápida e consome a produção desse dia. Javali que bate em muralha fica
   atordoado e danifica a obra. Torres mostram o alcance no chão antes e depois da
   construção, incluindo variante. Corrida normal/evoluída dura 30/50 s; recuperação
   completa parado arma 1,5× para a corrida seguinte e vai no save.
10. O guia apresenta um objetivo contextual. Eventos são registros locais exportáveis
    pela pausa, sem transporte externo. Razão da escolha e semelhança percebida exigem
    observação humana; nunca se inferem da sobrevivência automática.

## Compatibilidade e limites

Save v10 guarda chegada, tarefa e progresso, carga, cicatriz, companhia, batalhas,
baús, descanso e trabalho. V9 e anteriores não repetem o prólogo; o castelo herdado
continua Fortaleza, com seus investimentos e pessoas. IDs de obras anteriores não
mudam. Carregar duas vezes não desloca a sede novamente.

Não há dependência nova nem edição de `art/` ou `audio/`. As formas são provisórias.
Valores não decididos permanecem `_proposed`, com Q-232/Q-233; não são balanceamento
final aprovado. As metas de tempo são hipóteses, não uma alteração forçada do relógio.
O protocolo de 5–8 jogadores antecede a arte final. A repetição do ritual em postos
de expansão fica explicitamente ligada a RG-12/RG-13; as marchas e vassalos existentes
continuam funcionando, sem inventar uma rede territorial que o painel deixou para depois.

## Validação

Testes cobrem contrato inicial, bandeira gratuita, reserva, trabalho presencial,
exclusão de mão de obra, diferença espacial, alerta anterior a criaturas, perda e
proteção, reload repetido, baús próprios/estrangeiros, os três perfis em batalha,
defesa por estágio, alcance de torre, reparos, javali e descanso persistente. A suíte
existente verifica campanha, economia, monarcas, sucessão e salvamento. Vistoria,
exportação e navegador verificam a integração; o resultado humano permanece por medir.
