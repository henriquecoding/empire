> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 3. Escala, paleta e prova de construção nativa

### 3.1 Frame, corpo e rosto são medidas diferentes

Uma célula de 64×64 pode conter um corpo de 44 px e margem para as machadinhas. O chapéu ou a bandeira não devem tornar o corpo do bardo artificialmente maior. A reserva de margem precisa de ser testada na extensão máxima da ação.

| Personagem | Frame proposto | Altura útil orientadora, em pé | Região orientadora da cabeça |
| --- | --- | --- | --- |
| Rei | 96×96 | 70–76 px | Aproximadamente 22–26 px |
| Escudeiro protetor | 64×64 | 36–44 px | Aproximadamente 14–18 px com elmo |
| Nia | 64×64 | 42–46 px | Aproximadamente 16–20 px com cabelo |
| Bardo | 64×64 | 40–44 px de corpo; conjunto até 56 px | Aproximadamente 18–22 px com chapéu |
| Arqueiro | 96×96 | 64–70 px | Aproximadamente 18–22 px com capuz/coroa |
| Intendente | 64×64 | 35–40 px; conjunto até 54 px | Aproximadamente 16–18 px com gorro |
| Imperador de armadura | 128×128 | 90–98 px | Volume do elmo e encaixe entre ombreiras |
| Dançarina | 64×64 | 40–45 px | Aproximadamente 14–18 px, além do coque |

São metas para a autoria final. A validação compara o elenco na mesma linha de chão e sobre os cenários do jogo. O imperador sentado fica naturalmente mais baixo sem que o seu corpo seja reduzido por escala.

### 3.2 Detalhe moderado e cor do nariz

- Dois tons por tecido como ponto de partida; um terceiro só quando tiver função clara.
- Materiais distinguem-se pela organização das massas: metal com acentos concentrados; linho com dobras amplas; couro com blocos pequenos bem colocados.
- Testa, bochecha e parte iluminada do nariz partilham a cor base de pele do personagem.
- A sombra sob o nariz usa a rampa de pele já existente, sem uma mancha cromática independente.
- Olhos, dentes e fivelas não recebem detalhe abaixo da grelha usada pelo resto do personagem.
- Um ou dois grupos de dentes comunicam melhor a expressão pequena do que uma dentição desenhada individualmente.
- A identidade deve sobreviver em fundo claro e escuro. Contorno e contraste interior são avaliados separadamente.

O detalhe não é medido por uma proibição absoluta de pixels isolados. Um olho ou um acento pode justificar um deles; dezenas de pontos sem função enfraquecem a leitura.

### 3.3 Prova técnica produzida e verificada

A folha EMPIRE-ROSTOS-PROVA-NATIVA-64x64.png contém **18 células de 64×64**, organizadas em seis colunas e três linhas; o arquivo completo mede **384×192**.

O rei foi construído numa grelha de 24×24, o escudeiro numa de 16×16 e o intendente numa de 20×20, com coordenadas inteiras e paleta explícita. São amostras didáticas independentes, não redução automática das pranchas e não sprites corporais finais.

A conferência dos PNGs exportados verificou:

| Verificação realizada | Resultado |
| --- | --- |
| Quantidade e tamanho das células | 18 células; todas 64×64 |
| Canal alpha | Apenas 0 e 255 |
| Cores opacas por cabeça | 7–8 nesta demonstração |
| Silhueta externa durante a troca de expressão | Idêntica nas seis variantes de cada cabeça |
| Pixels fora das regiões faciais autorizadas | Sem alterações entre estados |
| Nariz na cor base da pele | Verificado nas três séries |
| Bigode do intendente | Todos os pixels da camada preservados nos seis estados |
| Estados distintos | Seis imagens diferentes por cabeça |
| Ampliação de inspeção | 6× por nearest neighbor, com exemplo a 1× |

A prova verifica integridade da construção. A avaliação da beleza, da personalidade e do nível de detalhe continua a depender da revisão artística e das pranchas preferidas.

Arquivos complementares: [folha nativa](../estudos/EMPIRE-ROSTOS-PROVA-NATIVA-64x64.png) e [painel de inspeção](../estudos/EMPIRE-PROVA-EXPRESSOES-GRELHA.png).

