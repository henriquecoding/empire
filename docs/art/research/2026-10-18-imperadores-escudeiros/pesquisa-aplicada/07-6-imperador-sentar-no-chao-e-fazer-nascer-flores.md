> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 6. Imperador: sentar no chão e fazer nascer flores

Esta revisão torna a presença do imperador mais ameaçadora e elimina o suporte sob ele. A capa pode tocar o terreno; não funciona como assento elevado. O corpo mantém o seu volume ao baixar. A armadura e o elmo escuros mantêm o mesmo desenho ao surgir o campo florido, sem ganhar uma cara sorridente ou cores brilhantes.

### 6.1 Anatomia e peso da ação

- A descida envolve quadril e joelhos; o tronco compensa o peso antes do contacto.
- O apoio termina diretamente no solo, com as pernas à frente e as botas separadas o suficiente para ler a pose.
- As mãos repousam sobre os joelhos e os ombros descem.
- Ombreiras, cotovelos e joelheiras conservam a articulação. Não se comprime toda a armadura como uma peça de borracha.
- O elmo inclina-se com cansaço. Ao recuperar, o alívio é pequeno e corporal.
- Ao levantar, o peso precisa voltar aos pés antes de o corpo completar a subida.

### 6.2 Sequência visual proposta

| Momento | Corpo | Plantas |
| --- | --- | --- |
| Descer | Quadril baixa; joelhos dobram; massa ainda sustentada | Chão livre |
| Sentar | Nádegas assentes; pernas à frente; mãos nos joelhos | Chão livre |
| Brotar | Corpo já estabilizado na pose de repouso | Folhas pequenas e botões em pontos definidos |
| Florir | Mesmo corpo sentado | Flores rosa/magenta, amarelas e azuis com centros claros |
| Recuperar | Respiração e pequeno movimento de repouso | Crescimento concluído; movimento discreto quando necessário |
| Levantar | Transferência de peso e regresso ao apoio | Continuidade visual definida pela duração do efeito |

Os quatro estudos da faixa de sequência apresentada mostram os primeiros quatro momentos. Eles não são uma folha final com o ciclo completo de levantar.

Como proposta de autoria, a descida pode partir de seis quadros a 10 fps e o repouso usa os oito quadros previstos para heal. O crescimento recebe uma linha de tempo própria. Estes números não alteram a cura ou o tempo da habilidade na simulação.

### 6.3 Construção das flores

- Flores pequenas mas cromaticamente claras: três famílias principais de pétalas, com folhas e caules a sustentá-las.
- Controlo de grupos em vez de pontos coloridos dispersos.
- Botões surgem nos mesmos pontos em que as flores abrem.
- A flor cresce a partir do solo. Não nasce do elmo, de uma luva ou de dentro da armadura.
- A vegetação conserva intervalos em torno de botas e mãos, para não esconder o contacto com o chão.
- As flores pertencem ao efeito do imperador. A pose da dançarina não a transforma na fonte da floração.

### 6.4 Regras para a futura integração

O corpo e a flora são camadas independentes. A referência do efeito é um ponto de chão coerente com a posição do personagem. A origem de apresentação mantém-se estável ao sentar; não é recalculada pelo retângulo aparente do corpo.

O evento de entrada no estado de repouso inicia o efeito uma vez. O loop corporal não deve gerar uma nova camada de flores em cada repetição. O número de elementos e a ordem de crescimento precisam ser estáveis para a mesma execução visual.

Interrupção, saída e nova entrada na habilidade precisam de ser revistas: sem flores duplicadas, corpo a saltar para outra posição, plantas suspensas ou desaparecimento abrupto no meio de um quadro. A persistência das flores e a sua eventual função no mundo continuam decisões de gameplay; o conceito não lhes atribui colisão, recursos, dano ou bónus adicionais.


