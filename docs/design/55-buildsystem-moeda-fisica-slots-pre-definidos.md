# 55 — Construção · BuildSystem — moeda física, slots pré-definidos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Contrato territorial atual e extensão: RealmGrowth consulta a recusa de território derivada pelo RG-28 antes de autorizar a obra. A §92 define o avaliador comum e a §95 a revalidação por revisão do mundo; elegibilidade futura inclui acessos/direitos, além do alcance atual.

- **Contrato** — Uma obra existe quando uma moeda cai num BuildSlot. O construtor vai lá, e o progresso avança enquanto ele estiver presente — não por tempo decorrido. É o que torna os construtores um recurso real.
- **Estados** — EMPTY → SCAFFOLD → BUILDING(ratio) → DONE → DAMAGED(ratio) → RUIN. Cada um é um frame de sprite, não uma cena diferente.
- **Muralhas** — Cinco níveis. Cada subida emite wall_upgraded, que muda material, silhueta e número de slots de contacto — os três ao mesmo tempo, porque é a mesma decisão de design.
- **Destruição** — wall_breached é o único evento com direito a tremor de ecrã (máx. 4 px, §24). Nunca golpes normais.

Os slots de construção são autorados na cena do segmento, não calculados. É a decisão do §21: forçar posições arriscadas em vez de deixar amontoar tudo no sítio seguro. O gerador escolhe segmentos; o segmento decide onde se pode construir.

Fundação e expansão atuais: confirmar a fundação válida é gratuito e idempotente; os estágios seguintes são pagos. Bancas nascem só após fundar, dentro do primeiro recinto. Obra disponível depende também de estágio, expansão, apoio e maturidade (Q-221/Q-227/Q-233). Ao reservar solo/subsolo, respeitar §87/§88 e o conflito da Q-237.
