# ADR 0066 — A caravana escolhe onde o Império nasce

- **Estado:** aceite como direção de design pelo pedido de 05/10/2026; migração Solo neste diff.
- **Tarefa:** RG-23.
- **Fonte:** documento mestre fornecido pelo dono, consolidado em `docs/reports/EMPIRE-MASTER.md`.
- **Substitui parcialmente:** ADR 0065, apenas os dois estandartes obrigatórios, caravana imóvel e deslocação do terreno na fundação nova.
- **Conserva:** reserva física, fundação gratuita, trabalho presencial, ofícios pagos, companhia paga, progressão da sede e compatibilidade.

## Precedência

O pedido desta sessão dá preferência ao relatório fornecido quando contradiz uma resposta
mais antiga ou uma proposta aprovada em contexto anterior. Respostas compatíveis completam
o relatório. Uma aprovação não transforma uma implementação futura em funcionalidade pronta.
As ADRs antigas conservam o histórico; os conflitos ficam na matriz do relatório.

## Fundação Solo

A carroça e os três cidadãos sem ofício seguem o monarca antes da fundação. Os IDs dos
cidadãos formam o grupo provisório; não se geram construtores, soldados ou companhia.
Na fundação, essas pessoas passam a pertencer ao reino e continuam sem ofício. O
recrutamento por moeda da Q-230 conserva-se para pessoas exteriores ao grupo fundador.

O prompt aparece depois de parar, apenas na superfície e sem interação prioritária.
Entradas, segredos e âncoras da Podridão são protegidos. O validador aceita coordenadas
contínuas dentro do terreno disponível, sem uma lista de estandartes autorizados.
Confirmar volta a verificar a posição real da simulação e só pode comprometer uma sede.

O footprint limpa flora comum, sem moedas ou madeira. Nesta versão a vegetação é cenário
procedural sem IDs de entidade: `clear_manifest` guarda intervalos territoriais persistentes.
O mesmo filtro é aplicado ao campo e à vegetação que tapa o subsolo; entradas, água,
relevo e recursos de gameplay conservam-se. IDs de flora serão necessários quando a
vegetação se tornar entidade de simulação. O horizonte continua paisagem distante.

A assinatura inicial guarda bioma, recursos, ecossistema, posição, seed e versão. Clima
completo, adaptação de arquitetura e consequências económicas ambientais continuam em
RG-24. `PENDING_CLIMATE_MODEL` identifica a lacuna; não fabrica um clima medido.

## Dados e saves

Q-230 a Q-233 aprovam os parâmetros apresentados em 05/10; a aprovação não autoriza
reintroduzir lareira paga, estandartes fixos ou uma rede territorial concluída. Os novos
limiares de paragem e raio de limpeza permanecem propostas em `arrival.csv`.

Save v11 guarda grupo fundador, assinatura e manifestação de limpeza. V10 fundado
mantém sede, terreno e riqueza; não volta a limpar e fica `LEGACY_INFERRED`. V10 por
fundar recupera os IDs existentes do grupo. Não nasce nenhuma pessoa ou provisão no load.
Os percursos `road`/`grove` só permanecem para compatibilidade e testes históricos.

## Limites verificáveis

Esta migração não entrega Coop/PvP, servidor dedicado, snapshots, clima completo, mundo
social dormente nem civilizações emergentes. A blueprint de obras de casa continua
autorada; expandir para fora do footprint inicial pede autoria territorial dinâmica.
Essas lacunas são requisitos abertos, não exceções permanentes à visão canónica.
