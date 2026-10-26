# Forja — pixels coerentes, cores e continuidade visual

**Relatório técnico para o Claude · Empire · 25 de outubro de 2026**  
Pesquisa complementar ao relatório de armas e equipamentos de 24–25/10. Diagnóstico, medições e proposta de implementação. O código de produção e os assets não foram modificados.

## 1. A conclusão que deve orientar o trabalho

**A Forja precisa analisar a organização espacial das cores, além da transparência, da paleta e das dimensões.** Um pixel pode estar cercado por pixels opacos e, ainda assim, ser um ponto de cor sem relação com a forma. O detector atual de `orphans` não cobre esse caso. A quantização existente usa OKLab, o que é uma boa base, mas escolhe cores sem conhecer materiais, planos de luz ou a função do detalhe.

A melhoria visual procurada é continuidade: massas de cor que explicam o corpo, contornos legíveis, detalhes com propósito e estabilidade durante o movimento. Isso exige preservar olhos, brilhos, pontas, cordas e pequenas expressões. Apagar todos os pixels de um único ponto produziria outro problema.

As verificações desta pesquisa encontraram:

1. **Ruído interno pode passar sem qualquer aviso.** Duas imagens sintéticas com o mesmo tamanho, as mesmas três cores e o mesmo histograma — uma com 16 pontos espalhados, outra com esses 16 pixels agrupados — passaram com zero erros e zero avisos. A limpeza não alterou nenhuma delas.
2. **Proteção de região não é uniforme entre etapas.** `cleanup.clean` respeita `protect`, mas `pipeline.finish` continua com quantização e outras operações que não recebem essa proteção. Uma cor protegida foi preservada na limpeza e alterada no resultado final do teste.
3. **O orçamento de cores pode não ser aplicado.** Com uma paleta fornecida, `finish` escolhe esse ramo e não executa a redução por `opts.colors`. Um pedido de duas cores terminou com três no caso reproduzido.
4. **A correção temporal pode apagar informação deliberada.** A rotina `blink` eliminou um piscar de olho sintético; `deflicker` apagou o deslocamento de uma faixa de baixo contraste, tornando o segundo frame igual ao primeiro.
5. **Tamanho de componente não equivale a forma de cluster.** O teste atual de área aceita tanto um quadrado 2×2 quanto uma tira 1×4; uma rotina auxiliar baseada somente em conectividade ortogonal apagou uma diagonal válida de oito pixels.

Essas provas identificam comportamentos e lacunas do código. Não medem a frequência desses problemas no uso real, não demonstram a causa de cada defeito dos sprites anteriores e não constituem um benchmark de qualidade dos modelos PixelLab.

## 2. O que foi pesquisado e o que permanece limitado

### 2.1 Escopo efetivamente executado

| Evidência | Trabalho realizado | Alcance |
|---|---|---|
| Canal oficial PixelLab | Inventário de 200 itens públicos; paginação concluída nas abas Vídeos, Shorts e Live; tentativa individual de exportar legendas | 180 legendas obtidas, 20 não retornadas, 0 pendentes |
| Leitura dos vídeos | 40 fichamentos: 35 de vídeos/Shorts e cinco recortes temáticos das lives | Análise textual temática; não inspeção integral de todo o áudio e dos quadros |
| Pesquisa anterior | Relatório de armas de 24–25/10, catálogo histórico de 70 vídeos e pacote anterior | Continuidade histórica; números antigos não somados ao inventário atual |
| PixelLab público | Documentação de cor, dithering, referência, guidance, edição, resize, mapas e OpenAPI v2 | Contratos publicados; arquitetura interna do modelo não demonstrada |
| Fontes artísticas e externas | Saint11, Cure, OKLab, Aseprite, Godot; artigo de abstração com restrições, depixelização e projetos de recuperação de grade | Fundamentação e comparação de objetivos; ferramentas externas não executadas |
| Forja e assets | Leitura do código no snapshot, inspeção dos três PNGs anteriores e provas sintéticas com os módulos reais | Diagnóstico reproduzido; nenhuma mudança de produção |

| Seção pública | Itens | Legendas obtidas | Dessas, muito breves | Sem transcrição no exportador |
|---|---:|---:|---:|---:|
| Vídeos | 90 | 77 | 3 | 13 |
| Shorts | 105 | 98 | 17 | 7 |
| Lives arquivadas | 5 | 5 | 0 | 0 |

O dossiê `Dossie-PixelLab-200-Videos-2026-10-25.md` e o catálogo em CSV/JSON identificam cada item, idioma, marcas de tempo e situação. **20 legendas obtidas são muito breves**; obter um arquivo não comprova transcrição integral do áudio. A classificação usa menos de 25 palavras após retirar marcações e exige revisão, sem inferir ausência de fala.

**A solicitação de transcrever integralmente todos os vídeos não foi concluída.** A entrega apresenta fichamentos originais com referências, sem reprodução integral de conteúdo protegido de terceiros. Não houve reconhecimento de áudio independente dos itens sem legenda nem revisão audiovisual completa. Esta limitação é distinta da conclusão do inventário público.

O problema inicial de acesso às legendas foi parcialmente superado com exportação pública no navegador. Assim, os trechos deste relatório que citam novas legendas são efetivamente baseados nos arquivos obtidos; o diagnóstico antigo de “nenhuma nova transcrição disponível” foi substituído nesta revisão. O vidIQ foi conectado e consultado sem consumo de créditos de transcrição.

### 2.2 Snapshot e reprodutibilidade

- Repositório: `henriquecoding/empire`.
- `main` consultada: `4471cde384c94e8833e4e61347551ac8c69320b0`.
- Fontes de implementação: `tools/forja/`; contratos e documentos referenciados nas seções seguintes.
- Assets: pacote `Empire-Forja-Personagens-2026-10-23.zip`.
- Provas: `provas-pixels-cores.py`, com resultados em `evidencias/resultados.json` no pacote complementar.
- Não houve nova geração paga, treinamento de modelo, alteração de paleta, commit ou publicação nesta sessão.

O relatório usa quatro categorias de afirmação: **fonte pública**, **observação de código**, **resultado reproduzido** e **proposta**. As propostas não são recursos já implementados nem decisões artísticas que substituem a aprovação de Henrique.

## 3. O que as legendas do canal acrescentam ao diagnóstico

### 3.1 Evidências diretamente ligadas aos pixels e às cores

As observações abaixo vêm da leitura das legendas automáticas recuperadas. Os tempos são pontos de localização, não transcrição certificada nem inspeção visual de todos os quadros. O dossiê complementar contém os fichamentos e a matriz de cobertura dos 200 itens.

| Vídeo e trecho | Evidência relatada na aula | Consequência proposta para a Forja |
|---|---|---|
| [Reduce Colors](https://www.youtube.com/watch?v=WSbBuAwRm18), 1:13–3:17 e 4:39–5:14 | Limpa detalhes indesejados, estabelece a paleta antes dos estados e reaplica uma escolha comum às direções e animações | Aprovar estrutura antes de propagar cores; quantização e limpeza de clusters precisam de verificações próprias |
| [Full Game Character](https://www.youtube.com/watch?v=zqZiQBS3LX0), 6:38–7:21 e 14:00–15:42 | Pontos, contorno e pequenos vazios exigem edição; a cor de uma manga muda numa direção que precisa de correção | Conferir cores por parte do corpo e por orientação, inclusive em modelos apresentados como consistentes |
| [Walk Cycles](https://www.youtube.com/watch?v=8TRHAC3fUpo), 1:39–2:35 e 6:07–7:18 | Cabeça, mochila e olhos são corrigidos; frames aceitos alimentam os seguintes | Referência limpa é uma condição de entrada. Reutilizar um detalhe exige alinhamento e compatibilidade de pose |
| [Animated VFX](https://www.youtube.com/watch?v=t8FIMv-8QpI), 2:34–2:46, 5:48 e 7:42 | Há cintilação corrigida, pequenos pontos usados deliberadamente para iniciar gelo e pixels de cor indesejada num portal | Partículas intencionais precisam de exceção semântica; o mesmo tamanho de componente pode significar efeito ou defeito |
| [Inpainting Guide](https://www.youtube.com/watch?v=9eAlZlQmZBg), 1:34, 4:17 e 6:44 | A sobreposição deixa conteúdo antigo; mudanças externas à máscara pedem recorte; a revisão inclui pixels, perspectiva e cores | Verificar a imagem achatada e as diferenças externas, não apenas a camada gerada |
| [Animate with Text / Interpolate](https://www.youtube.com/watch?v=j2bE9gq914U), 3:48–4:37 | Mudanças na madeira de uma fogueira podem ser interpretadas como iluminação ou como instabilidade | Definir quais regiões são estáticas e quais recebem luz variável antes de corrigir frames |
| [GBA Sprites](https://www.youtube.com/watch?v=moCpjMOOBGk), 0:54, 2:36 e 8:32 | Limpa rotações, observa contorno duplicado e diferencia canvas de tamanho útil | O contrato deve registrar também escala do desenho e densidade de detalhe |
| [Character States](https://www.youtube.com/watch?v=oCJWxfEwX-o), 4:07–5:05 | Corrige boca e condiciona o espelhamento à simetria | Uma boca não deve ser congelada quando a ação exigir expressão; equipamento assimétrico não pode trocar de lado |
| [Images Pro Flash / Skeleton V3](https://www.youtube.com/watch?v=Y68m9k60Lg0), 9:16–13:23 | Recomendações mudam entre versões; texto expandido pode indicar uma orientação incompatível com a direção solicitada | Registrar versão e revisar o prompt final por direção; não copiar conselhos antigos como regra permanente |
| [Pro Tilesets](https://www.youtube.com/watch?v=MbkqpDUFkEg), 8:32–9:22 | A composição e a conexão diagonal precisam de ajustes | Distinguir selecionar a peça certa, corrigir a emenda e alterar os pixels do asset |
| [Tilesets beta](https://www.youtube.com/watch?v=sE1s5ZYfxqk), 3:04–4:17 | Depois do inpainting das escadas, remove pixels e ajusta bordas | Revisar a conexão no mapa composto, na perspectiva correta |
| [Scale Trick](https://www.youtube.com/watch?v=-L4Zyvklsc8), 0:11–0:54 | Gera um objeto ao lado do personagem para dar contexto de escala | A composição com personagem 64/80 deve participar da revisão desde o início |

### 3.2 Convergências e diferenças entre aulas

**O padrão recorrente é gerar, selecionar, limpar e só então reutilizar como contexto.** As aulas de skeleton e caminhada tornam esse ponto explícito. A aplicação à Forja é nossa: um resultado que passou no lint raster ainda não deveria tornar-se referência aprovada de geração.

**Nenhuma dessas aulas comprova um limpador universal de pixels desconexos.** Redução de cores resolve a quantidade e a associação cromática; máscara limita uma edição; skeleton controla pose; cada operação cobre parte do problema. O teste de histograma idêntico da seção 7 demonstra a lacuna que sobra no código local.

**Modelos e interfaces mudam.** Inpaint, Edit, imagem inicial, referência de estilo e referência de animação não recebem necessariamente a mesma forma de instrução. Uma aula antiga pede descrição do conjunto no inpainting; uma ferramenta de edição pode esperar a mudança desejada. O adaptador deve seguir a documentação do recurso exato e guardar sua versão.

**A linguagem promocional precisa ficar fora dos critérios de aceite.** Expressões como resultado perfeito, porcentagem do trabalho concluído ou ausência de deriva são avaliações dos apresentadores. A pesquisa não as converteu em métricas de desempenho. Também não contou Shorts que repetem uma aula como comprovação independente.

### 3.3 Referências com funções explícitas

| Papel | O que deve fixar | Verificação independente necessária |
|---|---|---|
| Identidade | Rosto, corpo, roupa e equipamento reconhecíveis | Cada pose e cada orientação |
| Estilo | Densidade de pixels, contorno, luz e economia de detalhe | Compatibilidade com o estilo aprovado do Empire |
| Construção | Forma e encaixe de arco, espada, escudo e mão | Contatos, oclusões e funcionamento do equipamento |
| Pose | Apoio, direção e ação | Margem do canvas, pivô e espaço para efeitos |
| Paleta/material | Cores permitidas e função das rampas | Distribuição espacial e estabilidade entre frames |

Preparar referências na escala real e conservar sua procedência. Uma saída ruidosa não deve entrar automaticamente no conjunto de referências; uma screenshot ampliada não prova resolução nativa. O dossiê oferece navegação até as aulas que permitem conferir cada observação.


## 4. O que a documentação oficial confirma

### 4.1 Redução de cores é uma etapa própria

A PixelLab reconhece que outras ferramentas podem produzir muitas cores parecidas. A ferramenta Reduce Colors quantiza a imagem e pode trabalhar com uma paleta escolhida. A documentação também descreve uma escolha compartilhada de cores ao processar vários frames. Isso confirma a necessidade de um acabamento cromático explícito, sem demonstrar que esse acabamento resolve a organização dos clusters. [P01]

**Aplicação proposta:** armazenar separadamente cores da fonte, cores após normalização e cores finais; revisar a preservação de materiais. Uma estatística de cores não substitui a inspeção espacial.

### 4.2 Orientar cores e forçar uma paleta têm forças diferentes

Nas opções publicadas, `Limit colors used` é descrito como um controle fraco; `Force colors` busca garantir adesão à paleta selecionada. A documentação distingue reduzir automaticamente, escolher uma quantidade e usar uma paleta específica. Não tratar uma frase do prompt como equivalente a uma restrição executada. [P02]

**Aplicação proposta:** o relatório da Forja precisa identificar se a paleta foi apenas solicitada, aplicada pelo fornecedor, remapeada localmente ou verificada no PNG final.

### 4.3 Dithering tem tamanho e intensidade

A documentação prevê padrões 2×2, 4×4 e 8×8, além de intensidade. [P03] São escolhas de textura e transição. No Empire, o contrato atual restringe dithering a contextos específicos; a existência da opção no fornecedor não muda esse contrato.

**Aplicação proposta:** manter desligado nos personagens e registrar a política por região nos casos permitidos. Um padrão deliberado no céu e uma dispersão acidental no rosto não podem receber o mesmo tratamento.

### 4.4 Imagem inicial e máscara ajudam a controlar estrutura

O guia de introdução recomenda esboços como imagem inicial e mostra correções sucessivas de partes problemáticas. A edição usa contexto e delimita onde alterar. [P04] A documentação de Inpaint v3 oferece máscara e opção de recorte. [P05]

**Aplicação proposta:** primeiro aprovar grandes formas e pontos de contato; depois solicitar acabamento local. Verificar a composição final e a preservação externa independentemente da promessa do fornecedor.

### 4.5 Guidance exagerado também pode gerar artefatos

A documentação alerta que peso de guidance excessivo pode produzir artefatos, como saturação exagerada. [P06] Isso não prova que guidance seja a causa do ruído atual, mas impede a recomendação simplista de aumentar todos os controles.

**Aplicação proposta:** comparar ajustes alterando uma variável por vez, com referência e tarefa constantes. Não otimizar apenas pela impressão de detalhe na imagem ampliada.

### 4.6 Redimensionar com IA é redesenhar

A ferramenta Resize é apresentada como uma regeneração em outro tamanho, não como escala simples. [P07] A conversão Image to pixel art possui comportamento próprio de redução e redimensionamento descrito na documentação. [P08]

**Aplicação proposta:** distinguir autoria nativa, recuperação de uma ampliação regular e redesenho para outro tamanho. Um arquivo de saída 80×80 não demonstra, sozinho, que o desenho foi concebido nessa grade.

### 4.7 Contexto preservado importa nas junções

O guia de mapas recomenda sobrepor parte da região já produzida e conservar conteúdo visível como referência ao expandir. [P09]

**Aplicação proposta:** nos cenários, conferir a transição entre trechos, além da qualidade de cada trecho isolado. Não preencher toda a seleção de reparo se isso remover o contexto de borda necessário ao gerador.

### 4.8 Uso da API sem confundir seus parâmetros

A especificação atual de `/v2/reduce-colors` aceita vários frames do mesmo tamanho e uma paleta compartilhada. `num_colors` e `palette_image` são mutuamente exclusivos; o retorno inclui a paleta para reutilização. O limite agregado publicado é de 512×512 pixels. [P10]

Para a Forja, a chamada proposta usa `palette_image` derivada das cores já autorizadas e `dithering: "none"` nos personagens. Conferir dimensões, alpha e pertencimento à paleta após o retorno. Não prometer que todas as cores fornecidas serão efetivamente usadas.

Na mesma especificação, `drift_threshold` compara desvios em relação ao primeiro frame; zero solicita correção de todos os frames, e valores maiores corrigem menos. Isso difere da lógica local, que compara pixels com o frame anterior usando distância menor que o limiar. O comentário de equivalência em `quantize.py` deve ser corrigido. Nenhuma equivalência de algoritmo interno foi demonstrada. [P10]

## 5. O que significa “pixel desconexo”

É necessário separar falhas que parecem semelhantes quando vistas pequenas:

| Tipo | Sinal visual | Diagnóstico apropriado | Intervenção candidata |
|---|---|---|---|
| Ilha de alpha | Ponto solto fora da figura | Componentes da máscara opaca | Remover apenas se não for partícula, ponta ou detalhe previsto |
| Singleton de cor | Um pixel sem vizinho da mesma cor dentro de uma massa | Componentes por cor e contexto local | Classificar função antes de fundir |
| Microvariação cromática | Muitos tons quase iguais ocupando fragmentos | Distâncias de cor e mapa de materiais | Consolidar uma rampa aprovada |
| Fragmentação de plano | Luz/sombra viram manchas sem explicar volume | Leitura de massas e planos | Redesenhar a região em grupos maiores |
| Degrau irregular | Curva tem uma quebra sem intenção | Análise do contorno e direção pretendida | Reposicionar poucos pixels |
| Banding | Faixas de sombra repetem a borda e ressaltam a grade | Relação entre bordas dos grupos | Alterar desenho e término das faixas |
| Dithering indevido | Xadrez/poeira toma uma área que deveria ser plana | Política regional e padrão espacial | Retirar mistura automática nessa região |
| Halo | Borda clara/escura muda com o fundo | Alpha, cor de recorte e composição | Corrigir recorte; revisar borda em vários fundos |
| Grade inconsistente | Partes têm pixels efetivos de tamanhos diferentes | Recuperação de grade e células impuras | Reconstruir a região na grade correta |
| Cintilação | O material “ferve” entre frames | Correspondência temporal da região | Estabilizar paleta e agrupamentos sem travar ação |
| Artefato de exibição | PNG está bom, jogo mostra espessuras variáveis | Escala, filtro, câmera e transformações | Corrigir renderização, não degradar o PNG |

**Pixel isolado não é sinônimo de erro.** Um olho de um pixel tem função, assim como um brilho ou uma estrela. Uma diagonal de um pixel de largura pode estar conectada apenas pelos cantos. A regra artística é justificar o detalhe, não eliminar toda exceção. Os textos originais de Saint11 e Cure sustentam essa distinção. [A01, A02]

### 5.1 Quatro níveis de organização

1. **Silhueta:** permite reconhecer corpo e objeto sem detalhes internos.
2. **Massas de valor:** separam planos, luz e sombra.
3. **Materiais e elementos funcionais:** diferenciam metal, tecido, pele, madeira e equipamento.
4. **Acentos:** olhos, boca, brilhos, costuras e sinais realmente necessários.

O último nível não pode compensar falhas nos três primeiros. Uma roupa com cinquenta marcas pequenas não ganha volume por acumulação. A técnica de cluster sketching começa com massas grandes e as refina; sua transferência para a Forja é uma ordem de construção e revisão, não um filtro universal. [A01]

### 5.2 Continuidade sem perder nitidez

Suavidade visual pode vir de curvas bem distribuídas, áreas de descanso, valores organizados e limites coerentes. Anti-alias desenhado usa pixels deliberados de transição; blur e interpolação automática alteram muitas relações de uma vez. A discussão original de Saint11 ressalta que o excesso de anti-alias também prejudica a leitura. [A03]

No Empire, conservar o contrato de contorno e sombreamento vigente. Uma técnica apresentada numa aula não autoriza criar novos tons ou bordas semitransparentes em sprites que exigem alpha binário. Quando uma transição não cabe nas cores permitidas, primeiro redesenhar a forma.

### 5.3 Não transformar toda diagonal em suspeita

Uma sequência de degraus alternando comprimentos pode ser a rasterização correta de uma reta com inclinação não inteira. Por exemplo, alternar segmentos de dois e três pixels não é automaticamente um erro. O teste precisa considerar a linha pretendida, a inclinação média e o contexto, em vez de exigir degraus todos iguais.

Também não existe exigência geral de progressão exponencial para curvas. Usar ritmo de curva como instrumento de revisão artística, não como fórmula rígida que deforma todas as silhuetas.

### 5.4 O que a pesquisa acadêmica e as ferramentas externas acrescentam

**Abstração espacial e paleta devem ser tratadas em conjunto.** Gerstner e colaboradores, em *Pixelated Image Abstraction with Integrated User Constraints* (2013), combinam mapeamento de regiões e escolha de uma paleta reduzida. Acrescentam controles de importância, restrições de pixels e de paleta. O objetivo é aproximar imagens de baixa resolução com intervenção do artista. A publicação sustenta a ligação entre forma e cor e o valor das restrições explícitas; não demonstra que a PixelLab utilize esse método. Para a Forja, a inferência é conservar sinais importantes e permitir subpaletas/restrições por região antes de perseguir uma redução global. O trabalho de 2013 amplia o estudo de 2012, e foi consultado pelo resumo e pelas seções públicas disponíveis, sem reproduzir seus experimentos. [R01]

**Conectividade diagonal é um problema real, mas depixelização tem outro objetivo.** Kopf e Lischinski (2011) discutem a ambiguidade de vizinhos diagonais e estruturas finas. Seu método produz representação vetorial e curvas para ampliação. O ensinamento transferível é examinar conectividade; aplicar curvas suaves ou vetorizar os sprites mudaria a linguagem do Empire e não é a proposta deste relatório. [R02]

**Reconstrução de grade e acabamento artístico são tarefas distintas.** O README do Pixel Art Fixer, da Retro Diffusion, descreve recuperar células de imagens ampliadas, grades deslocadas e tamanhos não inteiros. É um candidato para investigar entradas cuja grade esteja deformada, não prova de que corrige semanticamente pontos de cor num PNG nativo. Não foi instalado nem medido nesta pesquisa. [R03]

**Um benchmark de reconstrução pode inspirar parte da avaliação.** O projeto pixel-bench compara tamanho nativo, cores, posição dos pixels e alinhamento após distorções controladas. Os números de exemplos publicados pertencem aos autores; não são resultados da Forja. Usar esse desenho para testar recuperação de grade, separando-o do benchmark de clusters, equipamentos e intenção descrito aqui. [R04]

**Há outra implementação pública para grade não uniforme.** Proper Pixel Art apresenta recuperação de imagens que imitam pixel art e suporte a vídeo/GIF. A consulta foi ao README. Antes de qualquer adoção, o Claude teria de auditar licença, comportamento de alpha, escala, custos e preservação de detalhes com os assets do projeto. A existência do repositório não constitui recomendação de substituir o pipeline. [R05]

Essas fontes reforçam três decisões de arquitetura propostas: medir a grade antes de reparar detalhes; analisar cor junto com posição e material; aceitar restrições do artista como parte do problema. Não autorizam um filtro global que apague detalhes para maximizar uma nota estética.


## 6. Medições nos três personagens da entrega anterior

Foram lidos os PNGs finais originais, sem JPEG, sem redimensionamento e sem alteração. “N4” considera vizinhos de cima, baixo, esquerda e direita. “N8” também inclui as quatro diagonais. “Singleton” significa componente de exatamente um pixel da mesma cor RGB entre pixels opacos.

| Asset | Tela | Pixels opacos | Cores RGB opacas | Singletons N4 | Singletons N8 | Singletons N8 totalmente internos | Órfãos de alpha N8 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Rei | 80×80 | 2.783 | 27 | 247 | 97 | 89 | 0 |
| Arqueiro | 80×80 | 2.323 | 37 | 342 | 144 | 122 | 0 |
| Escudeiro | 64×64 | 1.845 | 46 | 230 | 94 | 84 | 0 |

**Esses números são candidatos de análise, não contagens de defeitos.** Incluem acentos legítimos, transições, formas finas e pixels cuja função exige inspeção. Não devem virar um botão para apagar 97, 144 ou 94 pixels.

Os singletons N8 representam aproximadamente 3,49%, 6,20% e 5,09% dos pixels opacos. O arqueiro tem a maior proporção neste conjunto, mas isso não é um ranking definitivo de qualidade: as formas e materiais são diferentes.

A execução atual de `lint.check` sobre esses PNGs retornou zero erros e um aviso de gradiente para cada asset. O relatório original também tinha aviso de subgrade; ele depende da fonte e das medições de `snap`, acrescentadas pelo pipeline completo. A ausência desse segundo aviso ao reler apenas o PNG não significa que o defeito foi corrigido.

### 6.1 Interpretação visual e prioridade de revisão

- **Rei:** conservar a leitura ampla do corpo e da capa. Inspecionar pontos nos limites do rosto, roupa e espada como regiões distintas. A cor da roupa já foi uma preocupação do estudo anterior; não decidir seu material apenas pela proximidade RGB/OKLab.
- **Arqueiro:** examinar transições entre capuz, rosto, braços, torso e equipamento. O arco/corda ainda exige a análise funcional do relatório anterior. Limpeza de cor não deve “resolver” uma corda apagando-a.
- **Escudeiro:** revisar pequenos tons de pele, capacete e escudo. A tela menor contém mais cores que as duas maiores neste lote; isso justifica investigar redundância e distribuição, mas não impõe uma redução arbitrária.

O próximo trabalho de autoria deve marcar quais candidatos realmente atrapalham a leitura a 1×. Uma região pode ser perfeita com dois pontos contrastantes e ruim com dez pontos quase iguais. A interpretação semântica é indispensável.

## 7. Provas reproduzidas com o código existente

Os experimentos usam imagens sintéticas simples para isolar comportamentos. Não são propostas de personagem. O script não chama APIs nem modifica o repositório; lê os módulos informados e grava evidências num diretório separado.

| Prova | Entrada e resultado observado | O que demonstra |
|---|---|---|
| Pontos dispersos versus grupo | 80×80, 2.440 pixels opacos, três cores, histograma idêntico. 16 singletons versus nenhum. Ambos: zero erros, zero avisos, zero mudanças na limpeza | Paleta correta e ausência de ilhas de alpha não detectam fragmentação cromática |
| Detalhe de baixo contraste | Um pixel RGB 105 sobre RGB 100; distância OKLab ≈0,01758. Removido sem proteção; preservado em `cleanup` com proteção | Contraste baixo não prova irrelevância; a máscara ajuda nesta etapa |
| Proteção até o final | O mesmo pixel protegido chegou a `finish` com 105 e saiu com 100 após a paleta | Proteção atual de limpeza não é invariância do pipeline inteiro |
| Paleta e orçamento | Paleta com três cores, `opts.colors=2`; saída com três cores | O ramo de paleta tem precedência sobre a redução por quantidade |
| Diagonal válida | Oito pixels em diagonal: oito singletons N4, nenhum N8. `min_cluster(size=2)` apagou os oito | N4 e área mínima, sozinhos, podem destruir traços finos |
| Área versus formato | Tira 1×4 e quadrado 2×2: nenhum aparece em `small_islands(size=2)` | Área quatro não garante largura/altura nem bloco 2×2 |
| Piscar de olho | Frames aberto–fechado–aberto, um pixel alterado, vizinhança parada. `blink` reabriu o frame intermediário | Mudança temporal local pode ser a própria ação |
| Movimento de baixo contraste | Faixa RGB 110 moveu uma coluna sobre fundo RGB 100. `deflicker(0.05)` alterou 24 pixels e igualou frame 2 a frame 1 | Comparar as mesmas coordenadas pode congelar movimento |
| Intensidade zero no helper de dithering | Imagem cinza-escura, paleta preto/branco, Bayer2 e `strength=0`: 128 de 256 pixels brancos | Zero não significa desligado nessa função; o parâmetro reinterpreta a mistura |

**Distinção de alcance:** `min_cluster` e o argumento explícito `strength=0` foram testados como rotinas auxiliares. Não foi demonstrado que esses caminhos causaram defeitos na entrega anterior. `finish` atualmente amplia pelo fator `contract.cluster`; não chama `min_cluster` nesse trecho. A prova temporal é do algoritmo, não uma afirmação de que os três PNGs estáticos tenham passado por ele.

### 7.1 Executar a prova no checkout correto

```bash
python provas-pixels-cores.py \
  --forja-dir /caminho/empire/tools/forja \
  --out /caminho/evidencias-pixels-cores
```

O argumento opcional `--assets` recebe a pasta com `rei/rei.png`, `arqueiro/arqueiro.png` e `escudeiro/escudeiro.png`. As medições desses arquivos já estão em `resultados.json`; não é necessário incluí-los novamente no pacote para reproduzir os casos sintéticos. O script requer Pillow, já utilizado pela Forja. Conferir commit e hashes antes de comparar resultados de versões diferentes.

## 8. Diagnóstico do código: conservar, estender e corrigir

| Componente | O que já faz bem | Limite observado | Mudança proposta |
|---|---|---|---|
| `color.py`, `palette.py` | Conversão para OKLab, distância perceptual, extração determinística | Semântica e posição não entram na escolha da cor mais próxima | Manter OKLab; restringir candidatos por material e proteger sinais relevantes |
| `quantize.to_palette` | Pertencimento exato a uma paleta | Cada pixel é decidido isoladamente; pode trocar o papel da cor | Mapear dentro de subpaletas autorizadas por região |
| `quantize.shared_palette` | Extrai cores para um conjunto de frames | Paleta compartilhada não impede mudança de posição dos grupos | Usar junto de análise temporal de regiões |
| `lint._structure` | Encontra pixels sem vizinhos opacos | Não encontra singletons cromáticos no interior | Adicionar diagnóstico próprio, com N4 e N8 |
| `cleanup.clean` | Políticas separadas e proteção local; evita apagar todo acento contrastante | Proximidade cromática e maioria local não determinam intenção | Distinguir suspeita, proposta e aplicação; proteção semântica |
| `small_islands` | Mede área de componente | Área é apresentada como se fosse dimensão de cluster | Nomear a métrica corretamente e separar teste de grade/bloco |
| `pipeline.finish` | Fluxo rastreável e adaptação aos contratos | Proteção não acompanha todos os operadores; `colors` perde efeito quando há paleta | Políticas de preservação de ponta a ponta e orçamento explícito |
| `quantize.deflicker`, `blink` | Tentam reduzir oscilação | Falta correspondência de movimento e intenção temporal | Diagnosticar primeiro; restringir correção a regiões estáveis confirmadas |
| `lint._style` | Procura xadrez e rampas | Heurísticas não cobrem todo ruído, banding ou estrutura dos planos | Relatórios regionais e revisão; não inventar certeza artística |
| `contracts.json` | Distingue categorias e resoluções | `royal_64` e `royal_80` não impõem limite de cores | Subpaleta por material; orçamento global apenas se formalmente escolhido |

### 8.1 Três detalhes que o Claude não deve interpretar errado

**A Forja já usa OKLab.** Recomendá-lo como se estivesse ausente duplicaria trabalho. A lacuna principal é que a distância perceptual não informa se um pixel pertence à pele, ao tecido ou ao fundo.

**`max_colors: null` não é erro por definição.** O contrato pode deliberadamente não fixar um teto global. O erro operacional é apresentar um pedido de quantidade como aplicado quando o ramo executado não o aplica. A solução deve distinguir ausência de orçamento, orçamento opcional e limite obrigatório.

**A intenção não está no histograma.** Os dois testes de três cores têm o mesmo histograma. Qualquer indicador que observe apenas frequências de cor dará a mesma resposta, embora a distribuição espacial seja diferente. Essa é uma prova direta da necessidade de análise espacial.

### 8.2 Referências exatas no snapshot

- `lint.py`: `_structure`, aproximadamente linhas 67–97; `_style` e `_ramps` mais adiante.
- `cleanup.py`: decisão de denoise em `clean`, aproximadamente linhas 72–84; `components`, `min_cluster` e `small_islands`, aproximadamente linhas 104–157.
- `quantize.py`: `to_palette`, linhas 30–48; `shared_palette`, 56–66; `deflicker` e `blink`, 81–133.
- `pipeline.py`: sequência de acabamento e precedência paleta/quantidade, aproximadamente linhas 100–127.

As funções são a referência estável; os números podem mudar com comentários ou novas versões. Os links para o commit estão no registro de fontes.

## 9. Respeitar os contratos do Empire

O pedido é melhorar o acabamento dentro da direção já escolhida. Os documentos do projeto consultados determinam contorno preto, dois tons por material e restrições de dithering; distinguem a escala de detalhe dos personagens e do cenário. Não substituir essas decisões por uma paleta ou estilo vistos numa aula.

| Aspecto | Base que deve ser preservada | Consequência para o trabalho |
|---|---|---|
| Elenco atual | `royal_64` e `royal_80`, com pivôs próprios | Usar 64×64 para o grupo menor e 80×80 para o maior; não migrar silenciosamente para telas antigas propostas |
| Unidade do personagem | Detalhe de 1 pixel permitido | Olhos, boca e cordas podem exigir sinais mínimos |
| Cenário | Detalhe maior, com regras específicas de 2/4 pixels | Aplicar políticas próprias; não transferir o orçamento do rosto para uma parede |
| Paleta | Paleta de trabalho do Empire, com 112 cores em famílias | Derivar subconjuntos; não introduzir automaticamente DB32, AAP-64 ou outras paletas de referência |
| Sombreamento | Dois tons por material na regra atual | Redundância deve ser investigada por material, não só pelo total do sprite |
| Transparência | Alpha binário nos sprites cobertos por esse contrato | Efeitos e composição de sombras devem seguir seus contratos específicos |
| Aprovação | Design, animação e integração são estados diferentes | Resultado válido no lint continua candidato até revisão artística |

Uma tela 80×80 possui 56,25% mais células que 64×64. Esse espaço precisa servir à forma e à expressão, não obrigatoriamente a mais cores ou marcas pequenas. Também não se deve forçar todo desenho a ocupar cada célula: margem, arma e movimento precisam caber. O contrato `useful_height` atual dos royals é amplo; usar a referência aprovada para avaliar a ocupação e registrar qualquer proposta de nova faixa.

## 10. Arquitetura proposta para a melhoria

**Objetivo inicial: acrescentar informação confiável antes de acrescentar uma limpeza mais agressiva.** A primeira versão deve conseguir dizer onde há suspeitas, por que foram marcadas e o que ainda não foi avaliado.

### 10.1 Entradas distintas

1. **Intenção:** tamanho, categoria, personagem, materiais, direção, paleta e referências aceitas.
2. **Imagem observada:** pixels reais, alpha, componentes, bordas e regiões.
3. **Anotações:** máscaras humanas ou propostas por um modelo, com origem e incerteza.
4. **Política de alteração:** onde pode mudar RGB, alpha, forma, material ou conteúdo.
5. **Veredito:** comparação entre intenção e evidência; estados independentes.

Um campo `eyes_protected: true` sem máscara correta não protege olhos. Um mapa de materiais gerado por IA também pode estar errado. Guardar quem criou a marcação e se ela foi revisada.

### 10.2 Sequência de processamento

| Etapa | Entrada | Saída necessária | Condição para avançar |
|---|---|---|---|
| Preparação | Brief e referências | Contrato resolvido, com origem de cada restrição | Sem contradição de tamanho, câmera ou paleta |
| Geração | Contrato e guia de massas/pose | Fonte imutável e metadados | Resposta íntegra e proveniência registrada |
| Grade e alpha | Fonte | Candidato na grade correta e relatório de perdas | Sem corte, mistura ou redimensionamento oculto |
| Análise de forma | Candidato | Silhueta, contatos, vazios e regiões | Defeitos estruturais encaminhados antes de polir |
| Organização cromática | Regiões e paleta | Cores por material, clusters e suspeitas | Proteções e contraste respeitados |
| Reparo | Máscara autorizada | Patch, composição final e diferença | Zero alteração externa no modo de preservação exata |
| Revisão temporal | Sequência e ações | Correspondências, mudanças justificadas | Movimento, expressões e eventos preservados |
| Revisão artística | Nativo, ampliação e cena | Aceito, rejeitado ou pendente | Decisão explícita, separada do lint |

Guardar cada imagem intermediária permite localizar a origem de uma regressão. Se os pontos já estão na fonte, a geração precisa de outro condicionamento. Se aparecem depois da paleta, revisar o mapeamento. Se só surgem no jogo, investigar a exibição.

### 10.3 Um contrato adicional, sem quebrar o existente

O exemplo abaixo é **uma proposta de formato**, não uma interface já disponível. Nomes de máscaras são simbólicos; o Claude deve validar a existência dos arquivos e sua dimensão.

```json
{
  "schema_version": "proposal-1",
  "asset_id": "archer-review-candidate",
  "raster_contract": "royal_80",
  "approval": "pending",
  "palette_policy": {
    "master": "art/palettes/empire_working.gpl",
    "strategy": "approved_material_subsets",
    "global_budget": null,
    "dither": "none"
  },
  "regions": [
    {
      "id": "face",
      "mask": "masks/face.png",
      "annotation_status": "human_reviewed",
      "allowed_ramp_id": "existing-approved-skin-ramp"
    },
    {
      "id": "bow_string",
      "mask": "masks/bow-string.png",
      "annotation_status": "human_reviewed",
      "role": "thin_structure",
      "preserve_connectivity": "8-neighbor"
    }
  ],
  "edit_policy": {
    "editable_mask": "masks/authorized-edit.png",
    "pixel_lock_mask": "masks/approved-pixels.png",
    "alpha_changes": "forbidden_outside_editable_mask",
    "outside_edit": "byte_identical"
  },
  "temporal_policy": {
    "mode": "diagnose_only",
    "intentional_actions": ["eye_blink"],
    "correspondence_required_for_autofix": true
  }
}
```

Conflitos devem falhar de maneira explícita. Exemplo: uma cor protegida não pertence à paleta obrigatória. Não há solução que simultaneamente preserve o pixel exato e o remapeie. Retornar o conflito e manter o candidato anterior; não declarar ambas as garantias cumpridas.

## 11. Como detectar ruído de cor sem destruir o desenho

### 11.1 Normalização de análise

- Medir na grade nativa, não na prévia ampliada.
- Excluir RGB de pixels totalmente transparentes das contagens de cor.
- Tratar a política de alpha explicitamente; não inferir forma de RGB escondido.
- Manter uma leitura da fonte e outra do candidato já quantizado. A redução de tons quase iguais pode mudar radicalmente o número de componentes.
- Usar a mesma conversão de cor em todos os indicadores e registrar a versão da paleta.

Se a fonte contém centenas de variantes próximas, a contagem exata por RGB vai superestimar a fragmentação relevante. Para diagnóstico de cores próximas, mapear a uma paleta de análise controlada. Não fazer fusão transitiva ilimitada do tipo “A perto de B, B perto de C, portanto A e C são iguais”: cadeias desse tipo podem unir cores que deveriam permanecer separadas.

### 11.2 Componentes e descritores

Para cada região e cor, registrar:

| Descritor | Utilidade | Cuidado |
|---|---|---|
| Área | Distingue ponto, pequeno grupo e massa | Área pequena pode ser funcional |
| Caixa delimitadora | Expõe tira, quadrado ou forma alongada | Caixa grande pode conter quase nada |
| Conectividade N4/N8 | Separa ilhas verdadeiras e diagonais | N4 sozinho superconta fragmentos de linhas |
| Distância à silhueta | Ajuda a diferenciar textura interna de borda | Um olho também é interno |
| Cores adjacentes e contraste | Mostra se há microvariação ou acento forte | Contraste não determina intenção |
| Contato com região/material | Impede fusão entre pele e equipamento | Segmentação incerta exige revisão |
| Persistência temporal | Revela pontos que surgem sem continuidade | Efeitos, expressões e brilhos podem aparecer por pouco tempo |
| Papel anotado | Protege olho, corda, ponta, flor, brilho | Não confiar em anotação automática não revisada |

O sistema deve marcar candidatos como `review`, `protected`, `expected` ou `inconclusive`. “Não avaliado” precisa ser diferente de “aprovado”.

### 11.3 Um detector inicial que já seria útil

Pseudocódigo de diagnóstico, deliberadamente conservador:

```text
para cada região conhecida:
    contar componentes por cor com N4 e N8
    localizar componentes de 1–3 pixels
    medir contato, contraste, posição e papel
    se houver proteção ou papel crítico:
        registrar como detalhe preservado
    senão, se a conexão existir apenas pela diagonal:
        registrar para análise de traço; não apagar
    senão, se o material/região não for confiável:
        registrar como inconclusivo
    senão:
        registrar suspeita com evidências e alternativas
```

O intervalo de 1–3 pixels é um ponto de partida para pesquisa, não um novo contrato artístico. Inicialmente, nenhuma porcentagem global deve apagar pixels automaticamente.

### 11.4 Definições de métricas propostas

Para uma região `R`, com `A(R)` pixels opacos:

- **S8(R):** quantidade de pixels pertencentes a componentes N8 de tamanho um, dividida por `A(R)`.
- **F(R):** quantidade de componentes N8 por 100 pixels opacos, apresentada junto da distribuição de áreas.
- **U(R):** candidatos sem papel conhecido e fora das máscaras protegidas; não implica erro confirmado.
- **E(P):** quantidade de pixels alterados na máscara de preservação exata `P`.
- **C(R):** pares de regiões adjacentes cujo contraste necessário se perdeu depois de uma operação.

Se `A(R)=0`, a taxa deve ser “não aplicável”, e não um zero que pareça aprovação. Comparar métricas antes/depois por região. A meta não é minimizar todos os componentes: uma imagem toda de uma cor teria ótimos números de compactação e péssima informação.

### 11.5 Autoajustes permitidos somente com prova local

Uma fusão candidata precisa passar por quatro verificações:

1. Está dentro da área autorizada e não toca detalhe protegido.
2. Mantém a máscara de alpha, salvo se essa mudança foi explicitamente autorizada.
3. Não rompe contatos, linhas finas, aberturas ou separações importantes.
4. Melhora o problema marcado sem criar outro problema de maior prioridade.

Na dúvida, devolver duas alternativas ou encaminhar para inpainting localizado. Uma cópia reversível com diferença visível é preferível a alteração silenciosa. Não aplicar opening, closing, filtro de mediana ou votação de vizinhança indiscriminadamente no sprite completo.

## 12. Cor por material e coerência de volume

### 12.1 Paleta global e paleta utilizada são coisas diferentes

As 112 cores de trabalho do Empire não são uma obrigação de usar todas em cada personagem. A paleta global organiza famílias. A imagem precisa usar os tons que explicam sua construção.

O método atual de extração pondera frequência e distância. Isso pode favorecer grandes áreas e perder cores raras, justamente onde há olhos, brilho e sinais pequenos. Por outro lado, preservar toda cor rara perpetua ruído. A decisão precisa considerar o papel da cor.

A proposta é selecionar **subpaletas aprovadas por material**, sempre contidas na paleta autorizada. Pele, couro, tecido e metal podem compartilhar cores quando isso funciona visualmente, mas não devem ser misturados apenas porque seus valores são próximos.

### 12.2 Plano de trabalho cromático

1. Marcar as massas principais e o material de cada uma.
2. Escolher os tons de luz e sombra permitidos para o material, respeitando a regra vigente.
3. Preservar as separações essenciais: rosto/capuz, mão/arma, braço/torso, escudo/corpo.
4. Consolidar cores redundantes dentro da mesma função.
5. Revisar a 1× e sobre fundos representativos.
6. Somente depois avaliar acentos e exceções já aprovadas.

Não converter automaticamente todo tecido vinho em um marrom próximo. Se a paleta não contém uma alternativa adequada dentro do material, registrar o problema. A ferramenta não deve editar a paleta mestra por conta própria.

### 12.3 Matiz, croma e luminosidade

A cor precisa ser avaliada em relação às vizinhas. HSV `V` não representa uniformemente a luminosidade percebida de diferentes matizes; o artigo original de OKLab explica essa limitação e a construção de um espaço perceptual. [A04] A Forja já utiliza esse recurso.

Isso não transforma distâncias em percentagens universais de visibilidade. Uma distância de 0,04 em OKLab não significa “4% de diferença percebida” em qualquer contexto. Tamanho do detalhe, fundo, vizinhança e função mudam o efeito visual. Os limiares 0,04, 0,05 ou 0,08 precisam de calibração no próprio conjunto de assets.

Mudanças de matiz entre luz e sombra podem enriquecer uma rampa; Saint11 demonstra a relação entre matiz, saturação e valor. [A05] Não transformar “luz quente/sombra fria” em automatismo para todos os materiais, biomas e iluminações. A rampa deve servir à direção existente.

### 12.4 Sombreamento precisa explicar a forma

Planos amplos pedem grupos legíveis; manchas arbitrárias não substituem a orientação da luz. O texto de sombreamento de Saint11 diferencia problemas de planos, luz e sombreamento que segue a borda em vez do volume. [A06]

No caso do Empire, a regra de dois tons por material favorece decisões claras: onde termina a luz e começa a sombra, qual face está voltada à iluminação e quais limites são construção do objeto. Brilhos não podem parecer novas peças nem bandas intermináveis ao redor da silhueta.

### 12.5 Otimização espacial: extensão posterior, não primeira entrega

Depois de existir um conjunto de referência revisado, pode-se experimentar uma função de custo:

```text
E = fidelidade_de_cor
  + penalidade_por_fragmentação_injustificada
  + penalidade_por_perda_de_borda_necessária
  + penalidade_por_mudança_de_material
  + penalidade_por_instabilidade_temporal
```

As cores candidatas de cada pixel ficam restritas à subpaleta da região. Pixels e relações protegidos são restrições rígidas, não apenas pequenos pesos que a otimização pode sacrificar.

Um termo de vizinhança simples pode favorecer rótulos iguais em áreas planas. Mas ele também tende a apagar dedos e cordas se aplicado sem contexto. Bordas confiáveis devem vir de máscaras, referências e regiões revisadas; usar toda borda ruidosa da própria fonte como verdade também impediria a limpeza.

Essa é uma proposta de engenharia, não uma descrição do algoritmo proprietário da PixelLab. Primeiro implementar diagnóstico, máscaras e um mapeamento regional determinístico. Só adicionar um otimizador se o benchmark mostrar ganho além dessa base.

## 13. Reparo localizado e proteção de ponta a ponta

### 13.1 Três garantias distintas

| Garantia | Exemplo | Teste |
|---|---|---|
| Pixel exato | Rosto já aprovado | Igualdade RGBA em cada posição protegida |
| Forma | Recolorir capa sem alterar seu recorte | Igualdade da máscara de alpha e de limites relevantes |
| Relação | Preservar mão na empunhadura | Contato e ordem de oclusão continuam coerentes |

Preservação semântica não é igualdade de bytes; igualdade de bytes também não prova um encaixe correto. O contrato de edição precisa dizer qual garantia vale em cada região.

### 13.2 Ordem recomendada para um patch

1. Duplicar o candidato aprovado e registrar seu hash.
2. Definir a região editável e as regiões protegidas.
3. Resolver coordenadas de máscaras antes e depois de crop, padding, escala e encaixe.
4. Gerar ou redesenhar apenas o conteúdo necessário, com contexto suficiente ao redor.
5. Normalizar a grade e as cores do patch dentro de suas permissões.
6. Recompor o patch sobre a fonte, distinguindo adicionar, substituir e remover.
7. Validar a imagem achatada final, incluindo a preservação externa.
8. Guardar diferenças e manter a possibilidade de voltar à versão anterior.

A checagem deve acontecer **depois da última operação que altera pixels**. Proteger antes da quantização e depois remapear tudo não preserva o rosto. Também não basta verificar a camada nova se a antiga permanece visível por baixo.

### 13.3 Política de impasse

Quando não for possível melhorar a região sem violar uma proteção, o sistema deve retornar `needs_review`, com motivo. Não ampliar a máscara silenciosamente, redesenhar outra parte ou alterar o contrato para fazer o lint ficar verde.

Uma máscara muito pequena pode impedir a reconstrução de uma curva ou de um volume. A solução é propor uma nova área de edição visualmente justificada, preservando a procedência da decisão; não esconder que a região necessária ficou maior.

## 14. Continuidade entre frames

Uma paleta estável é necessária, mas não suficiente. A mesma paleta pode produzir grupos de pixels que mudam de lugar de forma aleatória. Também pode acontecer o oposto: uma limpeza força os frames a ficarem parecidos e apaga a ação.

### 14.1 Separar quatro tipos de mudança

| Mudança | Exemplo | Tratamento |
|---|---|---|
| Movimento do corpo | Braço se desloca | Comparar regiões correspondentes, não a mesma coordenada de tela |
| Mudança de iluminação prevista | Brilho acompanha uma lâmina girando | Permitir mudança de cor com a orientação |
| Ação pequena | Piscar, respiração, flor surgindo | Preservar eventos e detalhes intencionais |
| Ruído | Ponto muda sem relação com forma ou ação | Candidato a correção, após excluir os casos anteriores |

### 14.2 Melhorias mínimas no módulo temporal

- Não executar correção automática em rosto, mãos, arma, flores ou efeitos sem política explícita.
- Compartilhar a seleção de paleta entre frames, sem recalcular uma paleta independente para cada um.
- Respeitar o contrato de movimento; não alinhar todos os frames para apagar salto, recuo ou deslocamento deliberado.
- Fazer correspondência por região, âncoras ou movimento anotado antes de comparar cores.
- Quando a correspondência for incerta, emitir diagnóstico e preservar o frame.
- Registrar frames e coordenadas alterados; revisar o loop em velocidade normal e quadro a quadro.

Não há motivo para começar com optical flow complexo. Uma primeira versão pode operar somente em regiões anotadas como estáticas, excluindo áreas expressivas e efeitos. Se depois for usado fluxo óptico, ele também precisa ser validado: oclusões e formas de um pixel podem tornar sua estimativa imprecisa.

### 14.3 Testes que não podem faltar

Preservar piscar de olhos, aparição orgânica de uma flor, corda tensionando, brilho móvel e passo de uma faixa de tecido. Detectar, separadamente, um ponto aleatório inserido em uma região confirmadamente estática. Conferir que a sequência não ficou mais imóvel apenas para obter melhor indicador de estabilidade.

## 15. Cenários, construções e transições

O mesmo tipo de defeito muda de impacto conforme a escala. Num rosto, um pixel pode ser toda a expressão; numa parede, dezenas de pontos de alto contraste podem disputar atenção com o jogador.

### 15.1 Políticas por plano

- **Plano distante:** massas amplas e orçamento de valores do contrato. Pequenos ruídos não devem virar suposta riqueza de detalhe.
- **Plano intermediário:** formas e materiais compreensíveis, com descanso visual.
- **Plano jogável:** entradas, plataformas, obstáculos e personagens distinguíveis.
- **Primeiro plano:** elementos decorativos não podem encobrir sinais importantes.
- **Efeitos:** padrões e partículas seguem sua própria política; não usar regra de roupa ou parede.

Essas são aplicações ao problema atual; os limites numéricos permanecem os dos documentos do jogo.

### 15.2 Não confundir três grades

1. Grade de pixel da imagem.
2. Escala gráfica dos detalhes, como blocos de 2/4 pixels.
3. Grade de tiles do mapa.

Um tile de 32 pixels não significa que todo detalhe deva ter 32 pixels. Um componente com área quatro não demonstra alinhamento de um bloco 2×2. Se a regra pretende blocos consistentes, verificar fase da grade, dimensões e uniformidade das células. Definir essa semântica antes de alterar a implementação.

### 15.3 Testar continuidade de borda

Montar tiles repetidos e trechos vizinhos numa composição. Inspecionar mudança de cor na emenda, altura do solo, repetição visível, densidade de textura e continuidade de linhas. A aprovação de um trecho isolado não garante uma paisagem contínua.

O personagem de 64/80 deve aparecer na composição desde a análise inicial. Um cenário muito detalhado pode ser bonito ampliado e tornar o elenco difícil de ler na escala real.

## 16. Verificar a exibição no jogo sem culpar o asset por tudo

A documentação Godot mostra que escalas fracionárias podem variar a espessura aparente dos pixels e descreve escala inteira para evitar essa distorção. [A09] Isso é uma causa possível a verificar, não um defeito demonstrado do deploy nesta sessão.

O teste de integração deve comparar o PNG nativo com sua exibição na resolução interna do projeto, a ampliação inteira e o movimento da câmera. Conferir filtros de textura e transformações conforme a configuração vigente. Não alterar a resolução interna do Empire para encaixar uma recomendação genérica.

Se o arquivo apresenta grupos coerentes e só “ferve” ao mover a câmera, investigar posicionamento e renderização. Se o problema já existe no PNG parado a 1×, a correção pertence ao asset/pipeline. Evitar tratar as duas causas com o mesmo filtro de suavização.

## 17. Pedidos melhores para o gerador

O compilador deve emitir um brief único, sem instruções conflitantes. “Muito detalhado”, “cinemático” e “texturas ricas” podem entrar em conflito com o desenho compacto pedido. Esse risco deve ser validado no resultado, não tratado como certeza sobre um fornecedor específico.

### 17.1 Conteúdo positivo do pedido

Descrever identidade, pose, câmera, forma das massas, iluminação prevista, materiais e detalhes críticos. Anexar referências coerentes no tamanho correto. O prompt deve explicar o que existe; a análise posterior verifica se foi respeitado.

Exemplo de orientação de acabamento, a adaptar ao contrato real:

```text
Use the approved Empire character reference and the resolved royal_80 canvas.
Keep the accepted silhouette, face, pose and equipment proportions.
Organize each material into the approved light and shadow shapes.
Keep broad connected color groups and clear separation between face, hood,
hands and equipment. Place small accents only where they describe a required
feature. Preserve the eye, mouth, bow string and arrow-tip marks explicitly.
Use the existing Empire palette and approved material ramps.
Keep the required black outline, hard pixel grid and binary transparency.
```

Essa orientação não promete que um gerador respeitará todas as condições. Os nomes de contrato precisam ser expandidos em valores compreensíveis pelo backend; não enviar apenas `royal_80` a um modelo que não conhece o projeto.

### 17.2 Pedido de reparo

```text
Within the marked cloth region, replace the scattered incidental color specks
with coherent light and shadow shapes using the approved cloth ramp.
Preserve the pose, silhouette, seams, face, hands and equipment.
Do not add decorative texture or alter pixels outside the authorized mask.
```

A máscara e a recomposição local são controles reais; a frase final é apenas intenção textual se o backend não oferecer garantia de preservação. Não pedir ao modelo que “apague todos os pixels soltos”.

### 17.3 Separar correção de conteúdo e de acabamento

Uma mão ausente, espada duplicada ou corda mal construída precisa de reparo de forma/conteúdo. Agrupar cores não resolve esse tipo de erro. O relatório anterior de armas continua válido como complemento: inventário, partes, contatos e oclusões precisam ser revisados antes do acabamento final.

## 18. Benchmark e critérios de aceitação

### 18.1 Conjunto inicial proposto

Preparar 48 imagens estáticas: 24 para calibrar políticas e 24 reservadas para avaliação. Equilibrar personagens de 64×64, personagens de 80×80 e recortes de cenário. Acrescentar oito sequências curtas para movimento, expressão, roupa, arma e efeitos.

Esses números são uma proposta de amostragem, não uma garantia estatística. As imagens precisam incluir referências aceitas e casos difíceis, além de corrupções controladas. Separar por personagem/origem, não apenas frames quase iguais distribuídos entre os dois grupos; isso evitará uma avaliação artificialmente fácil.

### 18.2 Rótulos úteis

Cada caso deve indicar:

- Regiões aceitas e regiões problemáticas.
- Pixels pequenos intencionais, com seu papel.
- Áreas em que pode mudar cor, forma ou alpha.
- Ação temporal esperada e frames de evento.
- Defeito a corrigir e importância visual.
- Estado da anotação: revisada, proposta ou inconclusiva.

Manter exemplos positivos de olhos, brilho, diagonal, corda, ponta de flecha, flor pequena e partícula. Sem esses controles, a ferramenta pode melhorar a detecção de ruído e piorar todos os detalhes que Henrique quer preservar.

### 18.3 Comparações necessárias

| Variante | Pergunta que responde |
|---|---|
| Forja atual | Qual é a linha de base? |
| Apenas paleta menor | Quanto se ganha só reduzindo cores e quanto se perde? |
| Diagnóstico por componentes | Onde a distribuição espacial acrescenta informação? |
| Subpaleta por material | Evita trocas indesejadas e fragmentos redundantes? |
| Máscaras e reparo localizado | Melhora a região preservando o restante? |
| Tratamento temporal restrito | Reduz cintilação sem apagar ação? |

Usar as mesmas entradas. Guardar a variante e os parâmetros. Não trocar ao mesmo tempo modelo, referência, prompt, paleta e limpeza e atribuir a melhora a uma única mudança.

### 18.4 Medidas e revisão humana

- Precisão e cobertura na marcação de **defeitos anotados**, separadas por categoria.
- Falsos positivos em detalhes intencionais.
- `E(P)=0` nas regiões com preservação exata.
- Contatos, vazios e linhas críticas preservados.
- Melhor leitura a 1× e no cenário, avaliada lado a lado sem rótulo da variante quando possível.
- Continuidade de materiais sem congelamento de movimento.
- Tempo de correção manual e número de tentativas por asset aceito.
- Custo real registrado apenas quando houver geração efetivamente executada.

Não usar quantidade de cores, quantidade de componentes, PSNR, SSIM ou uma nota de um modelo visual como juiz único de beleza. Uma otimização pode melhorar uma medida sacrificando informação. A decisão artística continua separada das garantias técnicas.

### 18.5 Metas rígidas versus metas a calibrar

**Rígidas quando declaradas no contrato:** tamanho correto, ausência de corte oculto, paleta autorizada, alpha permitido, preservação exata, arquivo íntegro e rastreabilidade.

**A calibrar:** densidade aceitável de pequenos grupos, quantidade ideal de candidatos, sensibilidade cromática, textura por material e preferências estéticas. Não inventar um “máximo universal de 2% de pixels soltos” ou fixar 16 cores para todo o elenco sem evidência e decisão artística.

## 19. Plano de implementação para o Claude

### Incremento 1 — observação e estados corretos

**Prioridade alta.** Estender o relatório com componentes de cor N4/N8, métricas regionais, contagem antes/depois e candidatos. Manter `orphans` de alpha com nome inequívoco. Acrescentar estados independentes para raster, coerência de cor, forma, temporalidade e aprovação artística.

Arquivos candidatos: `lint.py`, `review.py` e um módulo pequeno de análise de clusters. O Claude deve verificar o código atual e as regras de tamanho de arquivo do repositório antes de escolher a divisão.

Aceitação: a fixture de 16 pontos passa a ser distinguida do bloco no diagnóstico; ambos continuam com a mesma validação raster. O detector não apaga pixels e não chama os pontos de defeitos confirmados sem anotação.

### Incremento 2 — garantias de preservação

**Prioridade alta.** Fazer a política de proteção acompanhar todas as etapas que alteram pixels, ou finalizar a recomposição sob máscara após essas etapas. Validar coordenadas e conflitos. Conservar os controles de reparo existentes; não refazer o sistema do zero.

Aceitação: a prova de pixel protegido permanece idêntica no resultado final quando a garantia é exata. Se a paleta obrigatória for incompatível, o resultado é conflito explícito, não sucesso com pixel alterado.

### Incremento 3 — paleta e orçamento por material

**Prioridade alta.** Resolver a precedência entre `opts.colors`, paleta fornecida e limites do contrato. Quando ambos forem solicitados, produzir um subconjunto permitido que respeite as proteções ou rejeitar a combinação com explicação. Não ignorar uma opção silenciosamente.

Depois acrescentar mapeamento por material. Manter cores autorizadas, tratamento de regiões desconhecidas e relatório das perdas de contraste.

Aceitação: o teste de quantidade deixa de produzir uma falsa impressão de cumprimento; mão/arma, rosto/capuz e tecido/couro preservam separação nos casos anotados.

### Incremento 4 — temporalidade conservadora

**Prioridade alta antes de aplicar a novos lotes de animação.** Corrigir a afirmação de equivalência com o parâmetro PixelLab. Separar detecção de aplicação automática. Restringir alterações a regiões cuja correspondência e estabilidade foram confirmadas.

Aceitação: o piscar de olho e a faixa móvel sobrevivem; ruído inserido numa região estática é identificado. O relatório informa o que não pôde ser avaliado. Não alterar a duração ou quantidade de frames para esconder defeitos.

### Incremento 5 — curvas, estrutura fina e cenário

**Prioridade seguinte.** Distinguir área mínima, conectividade, largura local e escala de bloco. Criar controles positivos de diagonal e corda. Rever o significado de `cluster` no pipeline e no lint antes de mudar o comportamento.

Aceitação: a diagonal válida deixa de ser alvo de uma correção cega; tiras e blocos não são tratados como a mesma geometria. Contratos atuais de cenário não são substituídos por novas regras sem decisão registrada.

### Incremento 6 — interface de revisão e experimentos

Exibir nativo, ampliação inteira, versão anterior, versão candidata e mapa de diferenças. Permitir marcar um detalhe como intencional e reutilizar essa anotação. A ação de aplicar deve dizer qual região muda e qual problema pretende resolver.

Só depois comparar novos backends, parâmetros ou um otimizador espacial. Se a Forja não consegue preservar um olho aprovado, trocar o modelo ainda deixará a mesma fragilidade no acabamento.

### Ordem sugerida por risco

| Ordem | Entrega concreta | Prova de conclusão |
|---|---|---|
| 1 | Diagnóstico cromático separado de alpha | Contraste scatter/cluster visível no relatório |
| 2 | Proteção até a composição final | Zero mudanças não autorizadas; conflitos detectados |
| 3 | Orçamento e subpaletas explícitos | Nenhum pedido ignorado; materiais preservados |
| 4 | Temporalidade com intenção | Piscar e movimento mantidos |
| 5 | Reparo assistido por região | Melhora visual localizada a 1× |
| 6 | Ampliação do benchmark e backend | Ganho demonstrado fora dos casos de calibração |

Não há estimativa de prazo neste relatório: depende do estado do código no momento da execução e das referências disponíveis. Não há necessidade técnica demonstrada de treinar um modelo novo para começar a corrigir essas lacunas.

## 20. Casos mínimos para a suíte de comportamento

| Caso | Resultado desejado |
|---|---|
| Ponto opaco acidental fora da figura | Sinalizar conforme a categoria |
| Partícula prevista no mesmo local | Preservar e registrar sua função |
| Pontos cromáticos dispersos dentro da roupa | Marcar candidatos de fragmentação |
| Olho de um pixel | Preservar |
| Brilho de um pixel aprovado | Preservar |
| Marca de baixo contraste protegida | Preservar inclusive após quantização |
| Diagonal N8 contínua e N4 fragmentada | Não apagar por tamanho de componente |
| Corda de um pixel | Manter conexão e terminais |
| Tira 1×4 sob regra de bloco 2×2 | Avaliar geometria, sem confundir área e bloco |
| Regiões pele/couro com cores próximas | Não fundir sem política material |
| Duas cores pedidas com paleta maior | Aplicar sem violar proteção ou declarar conflito |
| Reparo que altera pixels externos | Rejeitar a composição no modo exato |
| Olho aberto–fechado–aberto | Conservar a ação |
| Faixa de tecido deslocada um pixel | Conservar movimento |
| Ponto aleatório em região temporal estática | Identificar candidato de cintilação |
| Dithering desativado | Nenhum padrão introduzido |
| Intensidade zero de dithering | Semântica explícita e testada; não presumir equivalência entre backends |
| Cena com personagem 64/80 | Legibilidade verificada na escala real |
| Câmera em movimento com PNG correto | Diagnosticar exibição separadamente |
| Ausência de máscara/material confiável | Retornar inconclusivo, não inventar aprovação |

Os testes devem verificar consequências, não apenas a presença de campos JSON ou copiar a implementação. A aprovação visual precisa de exemplos revisados; uma asserção de contagem não substitui esse julgamento.

## 21. O que evitar durante a implementação

1. “Resolver” tudo com um prompt maior.
2. Apagar todo componente de um pixel ou aplicar blur/mediana na imagem inteira.
3. Chamar toda conexão diagonal de erro.
4. Confundir quantidade de cores com uso coerente das cores.
5. Introduzir nova paleta ou aumentar o número de tons para esconder forma mal resolvida.
6. Marcar como corrigido um aviso que apenas deixou de ser medido.
7. Congelar frames para reduzir cintilação.
8. Transformar a textura de todos os materiais no mesmo padrão regular.
9. Tratar uma máscara prevista no manifesto como se tivesse sido confirmada nos pixels.
10. Aplicar parâmetros de fornecedores diferentes por nomes parecidos, sem conferir semântica.
11. Promover um estudo, PNG adaptado ou teste sintético a arte aprovada.
12. Afirmar que uma proposta deste relatório descreve a arquitetura interna da PixelLab.

## 22. Instrução pronta para o Claude

O texto abaixo é o encaminhamento da pesquisa. Ele pede implementação incremental e conserva a autoridade das decisões existentes.

> Leia `AGENTS.md`, `docs/art/FORJA.md`, `docs/art/PIXEL_ART_STUDY_GUIDE.md`, `docs/art/ASEPRITE_WORKFLOW.md`, `docs/art/ASSET_BIBLE.md` e os guias de personagem/animação aplicáveis. Use o relatório “Forja — pixels coerentes, cores e continuidade visual”, de 25/10/2026, junto do relatório anterior de armas e equipamentos.
>
> Trabalhe sobre o código atual, comparando-o com o snapshot `4471cde384c94e8833e4e61347551ac8c69320b0`. Preserve a paleta, os contratos do elenco 64×64/80×80, os controles de geração/jobs, a proveniência e a separação entre validade técnica e aprovação artística.
>
> O problema central reproduzido é que o detector de órfãos observa isolamento de alpha, enquanto pixels de cor desconexa dentro da figura podem passar sem aviso. Não apague singletons indiscriminadamente: olhos, brilhos, cordas, pontas, flores e diagonais podem ser necessários. A Forja já usa OKLab; acrescente análise espacial e material, em vez de reimplementar a distância de cor.
>
> Execute o script de provas num diretório separado. Comece acrescentando diagnóstico de componentes de cor N4/N8, diferenças antes/depois, candidatos por região e estados “não avaliado/inconclusivo”. A fixture dispersa e a agrupada têm histograma igual e devem ser distinguidas espacialmente, sem inventar aprovação artística automática.
>
> Corrija a proteção para que a garantia escolhida sobreviva ao acabamento final. `protect` hoje é aplicado na limpeza e não acompanha a quantização/contorno. Quando preservação exata e paleta obrigatória forem incompatíveis, retorne conflito explícito. Registre transformações de coordenadas das máscaras e valide a composição achatada.
>
> Resolva a precedência de `opts.colors` quando há paleta fornecida; a opção não deve ser silenciosamente ignorada. Introduza subpaletas por material, contidas na paleta autorizada, com política conservadora para regiões desconhecidas. Não imponha um teto arbitrário a todo o elenco nem altere a paleta mestra.
>
> Revise `deflicker` e `blink`: os testes mostram que podem apagar movimento de baixo contraste e um piscar intencional. Não os aplique cegamente às mesmas coordenadas. Use regiões estáveis confirmadas, exclusões semânticas e correspondência de movimento quando disponível; retorne inconclusivo quando faltar evidência. Corrija o comentário de equivalência com `drift_threshold` da PixelLab.
>
> Diferencie área de componente, conectividade N8 e bloco 2×2. A rotina auxiliar `min_cluster` não deve ser introduzida como solução global: ela apagou uma diagonal válida na prova. Verifique também a semântica de intensidade zero no helper de dithering antes de expor esse controle.
>
> Entregue primeiro um incremento observável e uma prova pequena com o arqueiro: agrupamento cromático por região, preservando rosto, braço, arco e corda. Mantenha a análise funcional de equipamentos do relatório anterior. Apresente PNG nativo, ampliação inteira, diferenças, máscaras, métricas e falhas restantes. Só expanda para o restante do elenco depois de demonstrar melhora sem regressão.
>
> Teste consequências visuais e preservação, não apenas schema. Registre versões e parâmetros. Consulte a matriz dos 200 vídeos: ela distingue legendas recuperadas, arquivos muito breves, itens sem transcrição retornada e fichamentos. Não afirme que todos os vídeos foram transcritos ou assistidos integralmente. As regras de cores foram confrontadas com a documentação e a API oficiais. As propostas de análise e correção são nossas, não uma reprodução comprovada dos modelos internos da PixelLab.

## 23. Fontes e rastreabilidade

Consultadas em 25/10/2026, salvo as notas históricas explicitamente identificadas. Os links dos vídeos estão na seção 3. A coluna “uso” limita a afirmação que a fonte sustenta; propostas de arquitetura e testes são desenvolvimento deste relatório.

### PixelLab — fontes primárias

| ID | Fonte | Uso |
|---|---|---|
| P01 | [Reduce Colors](https://www.pixellab.ai/docs/tools/reduce-colors) | Cores próximas, quantização, paleta e frames |
| P02 | [Color options](https://www.pixellab.ai/docs/options/color) | Diferença entre orientação e imposição de paleta |
| P03 | [Dithering options](https://www.pixellab.ai/docs/options/dithering) | Tamanho e intensidade de padrões |
| P04 | [Init images and inpainting](https://www.pixellab.ai/docs/getting-started) | Esboço inicial e correção iterativa |
| P05 | [Inpaint v3](https://www.pixellab.ai/docs/tools/inpaint-v3) | Máscara e opções de edição |
| P06 | [Guidance options](https://www.pixellab.ai/docs/options/guidance) | Peso de guidance e possibilidade de artefatos |
| P07 | [Resize](https://www.pixellab.ai/docs/tools/resize) | Redesenho com IA para outro tamanho |
| P08 | [Image to pixel art](https://www.pixellab.ai/docs/tools/image-to-pixel-art) | Comportamento de conversão e escala |
| P09 | [Using the Create Map tool](https://www.pixellab.ai/docs/guides/map-tiles) | Sobreposição e contexto em expansões |
| P10 | [OpenAPI v2](https://api.pixellab.ai/v2/openapi.json) | Contrato de redução de cores e descrição do controle de drift |
| P11 | [Create images from style references](https://www.pixellab.ai/docs/tools/consistent-style) | Uso de referências com estética compatível |
| P12 | [Edit image](https://www.pixellab.ai/docs/tools/edit-image) | Instruções de edição orientadas à mudança |

### Arte, cor e ferramentas — fontes originais

| ID | Fonte | Uso |
|---|---|---|
| A01 | [Pedro Medeiros: Cluster Sketching and Painting](https://saint11.art/pixel_art_articles/article2/) | Construção por massas, clusters e exceções de um pixel |
| A02 | [Cure: The Pixel Art Tutorial](https://pixeljoint.com/forum/forum_posts.asp?TID=11299) | Ruído, detalhes intencionais, banding e paletas |
| A03 | [Pedro Medeiros: Anti-Alias and Banding](https://saint11.art/pixel_art_articles/article5/) | Transições deliberadas e riscos de excesso |
| A04 | [Björn Ottosson: A perceptual color space for image processing](https://bottosson.github.io/posts/oklab/) | OKLab, luminosidade e comparação com HSV |
| A05 | [Pedro Medeiros: Basic Color Theory](https://saint11.art/pixel_art_articles/article6/) | Relações entre matiz, saturação, valor e iluminação |
| A06 | [Pedro Medeiros: Basic Shading](https://saint11.art/pixel_art_articles/article4/) | Planos, luz e erros de sombreamento |
| A07 | [Aseprite: Color Mode](https://www.aseprite.org/docs/color-mode/) | RGB/RGBA, indexação e transparência |
| A08 | [Aseprite: Context Bar](https://www.aseprite.org/docs/context-bar/) | Conectividade de quatro/oito vizinhos e ferramentas |
| A09 | [Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) | Exibição em escala inteira e artefatos de escala fracionária |

Os modos de cor do Aseprite ajudam a distinguir uma lista de cores sugeridas de uma imagem efetivamente indexada: em RGB, o pixel pode carregar cores fora da lista de trabalho; em Indexed, ele aponta para uma entrada da paleta. [A07] A distinção N4/N8 também aparece explicitamente na documentação da ferramenta. [A08] Esses conceitos apoiam o diagnóstico, sem substituir o contrato de exportação do jogo.

### Pesquisa acadêmica e reconstrução — fontes primárias adicionais

| ID | Fonte | Uso e limite |
|---|---|---|
| R01 | [Gerstner et al. (2013), Pixelated Image Abstraction with Integrated User Constraints](https://www.sciencedirect.com/science/article/pii/S0097849313000046), DOI 10.1016/j.cag.2012.12.007 | Texto público: forma, paleta e restrições do usuário; sem reprodução dos experimentos |
| R02 | [Kopf e Lischinski (2011), Depixelizing Pixel Art](https://johanneskopf.de/publications/pixelart/) | Ambiguidade de conexão diagonal; o objetivo original é vetorização/ampliação |
| R03 | [Retro Diffusion / pixel-art-fixer](https://github.com/Retro-Diffusion/pixel-art-fixer) | README de recuperação de grade; sem execução ou benchmark local |
| R04 | [Retro Diffusion / pixel-bench](https://github.com/Retro-Diffusion/pixel-bench) | Desenho de benchmark para reconstrução, não julgamento semântico da arte |
| R05 | [Kenneth Allen / proper-pixel-art](https://github.com/KennethJAllen/proper-pixel-art) | README de recuperação de imagens/vídeos; implementação não auditada |

### Empire — fontes internas verificadas

- [AGENTS.md no snapshot](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/AGENTS.md).
- [Código da Forja](https://github.com/henriquecoding/empire/tree/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja).
- [Contratos raster](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/contracts.json).
- [Limpeza](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/cleanup.py).
- [Lint](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/lint.py).
- [Quantização e temporalidade](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/quantize.py).
- [Pipeline](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/pipeline.py).
- [Paleta e extração](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja/palette.py).
- [Asset Bible](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ASSET_BIBLE.md).
- [Guia de estudo](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/PIXEL_ART_STUDY_GUIDE.md).
- [Fluxo do Aseprite](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ASEPRITE_WORKFLOW.md).

Material anterior lido: `Relatorio-Forja-PixelLab-2026-10-24.md`, versão atual recuperada em 25/10, e `Forja-PixelLab-Pacote-Claude-2026-10-24.zip`. O catálogo histórico e suas notas não foram apresentados como novas leituras de legendas.

## 24. Estado desta entrega

**Concluído:** inventário público de 200 itens e verificação de exportação; 180 arquivos de legenda obtidos; 40 fichamentos; pesquisa documental e acadêmica; leitura do código; medições dos PNGs; provas locais; proposta incremental e instrução para o Claude.

**Ainda limitado:** 20 itens sem transcrição retornada; 20 arquivos muito breves; ausência de revisão audiovisual integral. A entrega é análise original e rastreável, não transcrição integral de todos os vídeos. Os anexos não contêm cópias completas das falas protegidas de terceiros.

**Não demonstrado:** qualidade de novas gerações, treinamento ou arquitetura interna dos modelos PixelLab, correção já aplicada à Forja, ganho artístico aprovado ou funcionamento de uma mudança no deploy. O código auditado pertence ao snapshot identificado, e precisa ser comparado com o checkout do Claude antes da implementação.

O primeiro resultado verificável esperado é identificar fragmentação cromática que o lint atual não distingue, preservar detalhes intencionais até a saída final e oferecer reparos locais cuja melhora possa ser julgada na escala real.
