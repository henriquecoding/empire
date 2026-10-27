# Como fazer engenharia reversa de um serviço de IA — método, limites e aplicação ao PixelLab

Pesquisa de 26/10/2026. Este documento responde à pergunta do dono — *como se faz engenharia reversa?* — e
diz, técnica a técnica, o que foi feito com o PixelLab, o que não foi e porquê. Os achados estão no
[dossiê](DOSSIE.md); a sondagem paga que falta, no [protocolo](PROTOCOLO-SONDAGEM.md).

> Não é aconselhamento jurídico. As secções sobre lei resumem fontes primárias para decidir o que um
> projeto de jogo pode fazer sem advogado; um uso comercial do resultado pede revisão por quem é.

## 1. O que é, e o que se pode recuperar

A definição de referência é a de Chikofsky e Cross (IEEE Software, 1990): engenharia reversa é analisar
um sistema para identificar os componentes e as relações entre eles e criar representações noutra forma
ou num nível de abstração mais alto. Por natureza **não muda o sistema**. Duas subáreas importam aqui:
a *redocumentação* (recuperar a documentação que falta) e a *recuperação de desenho* (juntar ao que se
observa conhecimento do domínio, informação externa e dedução, para chegar a abstrações que o código
sozinho não dá). [M01]

Num serviço de IA vendido na nuvem há três níveis, e só os dois primeiros estão ao alcance:

| Nível | O que é | Recuperável sem o fornecedor? |
| --- | --- | --- |
| Funcional | O que o serviço aceita, devolve, cobra e recusa: o contrato e o comportamento | Sim, por documentação, contrato público e experiências |
| Desenho | Como as peças se organizam: que gerador, que tela interna, que pós-processamento, que pilha | Em parte, por inferência testável; nunca com certeza |
| Implementação | Pesos, dados de treino, código do servidor | Não. E tentar (extração de modelo, destilação) viola os termos — ver §2.4 |

O objetivo útil para o Empire nunca foi copiar o PixelLab: é saber o bastante para **usar** o serviço
sem surpresas (o adaptador da Forja) e **construir** o que ele não dá (os contratos do jogo). Isto é o
desenho *clean room* clássico: uma equipa estuda e escreve uma especificação; quem implementa só vê a
especificação, nunca o código alheio. [M02] A Forja já segue esta separação: o relatório de 23/10 é a
especificação, e o código da Forja implementa capacidades gerais, não código do PixelLab.

## 2. Os limites: lei, contrato e ética

### 2.1 União Europeia e Portugal

- **Programas de computador** — Diretiva 2009/24/CE: o utilizador legítimo pode *observar, estudar ou
  testar* o funcionamento de um programa para determinar as ideias e princípios por trás dele, enquanto
  faz o que tem direito a fazer (art. 5.º, n.º 3); a descompilação só é permitida quando indispensável
  para a interoperabilidade e com condições (art. 6.º); cláusulas contratuais contrárias a estas exceções
  são nulas (art. 8.º e considerando 17). [M03] Em Portugal a regra veio pelo Decreto-Lei 252/94 (que
  transpôs a diretiva anterior, 91/250/CEE; a WIPO Lex marca esse texto como substituído — conferir a
  versão consolidada no Diário da República antes de citar artigos). [M04]
- **Funcionalidade não é obra** — o Tribunal de Justiça decidiu em *SAS Institute v World Programming*
  (C-406/10, 2012) que a funcionalidade de um programa, a linguagem de programação e o formato dos
  ficheiros de dados não são protegidos pelo direito de autor; o licenciado pode estudar o funcionamento;
  os manuais podem ser protegidos se forem criação intelectual. [M05] Consequência prática: reimplementar
  *o que* o PixelLab faz é lícito; copiar o texto da documentação, não.
- **Segredos comerciais** — a Diretiva (UE) 2016/943 considera lícita a obtenção de um segredo por
  *observação, estudo, desmontagem ou teste* de um produto disponibilizado ao público, desde que quem o
  faz não tenha um dever válido de limitar essa obtenção (art. 3.º, n.º 1, al. b)). [M06] Portugal
  transpôs-a no Código da Propriedade Industrial (DL 110/2018). [M07]

### 2.2 Suécia (a lei dos termos do PixelLab)

Os termos do PixelLab regem-se pela lei sueca (cláusula 7.1). A Suécia transpôs a diretiva dos segredos
na *lag (2018:558) om företagshemligheter*, que só proíbe o "ataque não autorizado" a um segredo (4 §).
[M08] A leitura de páginas públicas e o uso da API oficial dentro dos termos não são ataques; contornar
autenticação ou usar uma interface fora dos termos pode ser.

### 2.3 Estados Unidos (onde está grande parte da jurisprudência)

- A engenharia reversa não é "meio impróprio" de obter um segredo (18 U.S.C. § 1839(6)(B)). [M09]
- A DMCA tem uma exceção para engenharia reversa com fim de interoperabilidade (17 U.S.C. § 1201(f)). [M10]
- *Sega v. Accolade* (1992) e *Sony v. Connectix* (2000): a desmontagem intermédia para chegar a
  elementos funcionais pode ser uso justo. [M11]
- *Bowers v. Baystate* (2003): um contrato pode proibir a engenharia reversa — o contrato pesa. [M12]
- *Van Buren v. United States* (2021): o "acesso excedendo a autorização" da CFAA é uma questão de portas
  fechadas ou abertas, não de intenção; *hiQ v. LinkedIn* (2022): dados públicos sem autenticação.
  [M13] *Google v. Oracle* (2021): reutilizar declarações de uma API para outro programa foi uso justo. [M14]

### 2.4 O contrato que vale aqui: os termos do PixelLab

Lidos a 26/10/2026 (última atualização declarada: 23/11/2025). O que muda o método:

| Cláusula | O que diz | O que fazemos |
| --- | --- | --- |
| 1.2 e 3.3 | Não treinar modelos próprios com imagens geradas pelo PixelLab sem autorização escrita | Nenhuma saída do PixelLab entra em treino, destilação ou pares automáticos. As sondas guardam-se em `build/` e servem para medir, não para ensinar |
| 2.2 | Uso programático só pela API oficial (api.pixellab.ai); construir um serviço próprio ou revender pede contacto | Nada de automatizar a interface web, nem de chamar rotas internas descobertas em JavaScript. As sondas usam só a API documentada |
| 3.1–3.2 | Software e algoritmos são deles; não copiar, modificar nem distribuir partes do PixelLab | Não se redistribui documentação, imagens nem a especificação; guardam-se URLs, hashes e medidas |
| 4 | O utilizador obriga-se à licença Open RAIL-M (ligação para a LICENSE do CompVis/stable-diffusion) | É também um indício técnico: ver o [dossiê, H01](DOSSIE.md#h01) |

### 2.5 O que **não** se faz, mesmo sendo tecnicamente possível

- **Extração de modelo** — consultar uma API para treinar uma cópia funcional. Está demonstrada na
  literatura (Tramèr et al., 2016; Carlini et al., 2024; o inquérito de Oliynyk et al., 2023) e é
  exatamente o que a cláusula 1.2 proíbe. [M15]
- **Testes ativos de segurança** — varrer portas, forçar rotas, contornar autenticação: o guia de testes
  da OWASP separa a recolha passiva (§4.1) dos testes que exigem autorização do dono do sistema. [M16]
- **Rotas privadas** — ler o JavaScript do site para descobrir chamadas internas e usá-las. Mesmo sendo
  código servido a qualquer visitante, usá-lo seria uso programático fora da API oficial (2.2), e não
  traria nada que a especificação pública não traga já.
- **Pessoas** — a OSINT fica ao nível da empresa: país, pilha, fornecedores, preços. Não se perfilam
  fundadores nem funcionários, e não se publicam endereços de email encontrados em DNS ou metadados.

## 3. O método: da evidência à inferência

### 3.1 A escada de evidência

Cada afirmação leva um nível. Subir de nível exige uma prova nova, não uma frase mais segura.

| Nível | Exemplo neste trabalho |
| --- | --- |
| **Facto publicado** — está numa fonte primária, com URL, data e hash | "Pixen: cada lado de 16 a 768, área até 512×512" (OpenAPI de 26/10) |
| **Medição reproduzível** — um script mede, e qualquer um repete | "O estimador de grade da Forja errava 7 de 16 saídas da documentação" (`forense.py`) |
| **Inferência testada** — uma hipótese com uma previsão que podia falhar e não falhou | "A tela do Pro é ~1024 px a escala 4/3/2" (preços, contagens e tetos, `inferencia_pro.py`) |
| **Hipótese** — compatível com os factos, sem teste ainda | "Os modelos clássicos são deterministas por seed" (sonda S01) |
| **Desconhecido** — a evidência pública não resolve | Pesos, dados, número de parâmetros, custo real por inferência |

Regra prática: a prosa usa o verbo do nível ("documenta", "mede", "coincide com", "sugere", "não se
sabe"). Um relatório que diz "o PixelLab usa X" sem nível é um relatório que não se pode corrigir.

### 3.2 Registar hipóteses antes de as testar

Cada hipótese tem: a afirmação, a evidência a favor, a evidência contra, **o que a refutaria** e a
experiência que decide. O [dossiê](DOSSIE.md#matriz) tem a matriz H01–H15. Escrever a previsão antes da
medição é o que distingue uma inferência de uma racionalização: a coincidência com a tabela do Gemini
(H03) só conta porque três das quatro tabelas testadas **não** coincidem.

### 3.3 Proveniência que sobrevive ao tempo

- URL, data, estado HTTP, bytes e SHA-256 de cada resposta (`coleta.py`), sem redistribuir o corpo.
- **Dois hashes**: o dos bytes e o do texto normalizado. O HTML do site é gerado pelo Next.js e leva um
  `buildId` que muda a cada publicação: dos 66 URLs da coleta de 23/10, só 2 têm hoje os mesmos bytes, e
  isso não quer dizer que 64 páginas mudaram de conteúdo. O hash de texto desta coleta é a base para a
  próxima comparação. Para JSON, o hash do JSON canónico (chaves ordenadas) ignora a formatação.
- Fontes dinâmicas mudam: um dos 200 vídeos do dossiê de 25/10 mudou de título entre a coleta e hoje.

### 3.4 Várias lentes, a mesma pergunta

O método "da caixa preta à planta" descrito por Fowler e pela Thoughtworks junta lentes (interface, dados,
tráfego, documentação) e mantém a origem de cada achado, com validação humana no fim. [M17] Aqui as
lentes são as camadas da §4; um achado vale mais quando duas camadas independentes concordam (a tela de
1024 px aparece nos preços **e** nas contagens de candidatos **e** nos tetos por proporção).

### 3.5 Experiências de caixa preta com desenho

Para um gerador de imagens servem as três famílias de testes do CheckList (Ribeiro et al., 2020),
pensadas para modelos de linguagem mas gerais: [M18]

- **Funcionalidade mínima (MFT)** — um pedido simples com resposta verificável: "64×64 devolve 64×64
  nativo" (S02).
- **Invariância (INV)** — uma mudança que não devia mudar o resultado: a mesma seed (S01), o exterior de
  uma máscara (S07).
- **Expectativa direcional (DIR)** — uma mudança que devia mover o resultado num sentido: mais força da
  imagem inicial preserva mais (S03); `lineless` tira contorno (S05).

E as regras de qualquer experiência paga: orçamento fixo antes de olhar, todas as saídas guardadas, uma
variável de cada vez, a decisão escrita antes do resultado.

## 4. Catálogo de técnicas, por camada

Para cada técnica: o que revela, o custo, o risco, e o que se fez com o PixelLab.

| Camada | Técnica | Revela | Risco | Com o PixelLab |
| --- | --- | --- | --- | --- |
| Produto | Documentação, FAQ, `llms.txt`, `llms-full.txt`, `sitemap.xml`, `robots.txt` | Capacidades, limites, controlos e vocabulário | Nenhum | Feito: 86 respostas recolhidas, ver `proveniencia.json` |
| Produto | Vídeos oficiais (legendas, demonstrações) | Comportamento real, defeitos que o apresentador corrige | Direitos sobre as falas: sintetizar, não transcrever | Feito a 25/10 (200 itens); conferido hoje pelo oEmbed |
| Contrato | Especificação OpenAPI com hash, impressão por operação e diferenças entre datas | O contrato exato e a sua deriva | Nenhum (GET público) | Feito: `contrato.py`; o hash mudou entre 23/10 e 26/10 |
| Contrato | Conformidade do nosso adaptador contra o contrato | O que a nossa ferramenta aceitaria e a API recusaria | Nenhum | Feito: 10 divergências na Forja, corrigidas |
| Contrato | Arqueologia de SDK (PyPI, npm, GitHub) | Que versões existem e que API cobrem | Nenhum (leitura estática, sem executar) | Feito: o SDK Python 1.0.5 só fala com a v1 |
| Pilha | Impressão digital pelo próprio contrato (nomes de esquemas, `operationId`) | Linguagem, framework, organização do código | Nenhum | Feito: FastAPI/Pydantic, módulos `app/endpoints/external/v2/*` |
| Infraestrutura | DNS público (A, CNAME, MX, TXT), registos de transparência de certificados (RFC 9162), cabeçalhos HTTP | Alojamento, CDN, fornecedores, subdomínios | Nenhum se passivo; não varrer portas | Feito: AWS eu-west-1 para a API, Cloudflare para o site, Supabase, Backblaze, Paddle |
| Cliente | Extensão do Aseprite, integração Pixelorama | Protocolo do cliente (websocket, campos) | Termos 2.2 e 3.2; a lei permite estudar para interoperabilidade, mas não é preciso | Não feito: o contrato público é mais rico e não exige isto |
| Cliente | Bundles JavaScript do site | Rotas internas | Usá-las viola 2.2 | Não feito, de propósito (só se leu o HTML para identificar Next.js e Chakra UI) |
| Comportamento | Sondas MFT/INV/DIR pela API oficial | Determinismo, eficácia dos controlos, limites reais | Custo; termos 1.2 (não treinar) | Planeado: 29 chamadas, cerca de US$0,44, à espera de chave e teto |
| Forense | Escala exata, grade, paleta, quase-duplicados, alfa, metadados (PNG, EXIF, C2PA) das saídas públicas | Como as imagens foram gravadas; sinais de geração em cor contínua | Não redistribuir as imagens | Feito: `forense.py` sobre 60 imagens da documentação |
| Forense | Atribuição de modelo (impressões digitais de GAN e de difusão, erro de reconstrução do autoencoder, *model parsing*) | Que família de modelo gerou uma imagem grande | Baixo | Não aplicável às saídas: a redução para pixel art apaga esses sinais. Só faria sentido nas saídas Pro grandes, e mesmo aí é fraco |
| Artefactos ML | Hugging Face, artigos, patentes | Linhagem de modelos, receitas | Licenças dos pesos | Feito: um modelo público (Pixel Party XL, SDXL, 2023); nenhuma patente encontrada |
| Organização | País, pagamentos, vagas, entrevistas, preços | Escala, custos, prioridades | Não perfilar pessoas | Feito ao nível da empresa |
| Terceiros | Benchmarks e ferramentas independentes | Comparações que o fornecedor não publica | Amostras pequenas | Lido: um benchmark cego de 124 gerações (julho de 2026) |

As técnicas de atribuição merecem uma nota, porque parecem a "engenharia reversa a sério" e aqui
falham por razões medíveis. As impressões digitais de GAN (Yu et al., 2019), a deteção de imagens de
difusão (Corvi et al., 2023), o erro de reconstrução do autoencoder (AEROBLADE, Ricker et al., 2024) e o
*model parsing* de hiperparâmetros (Asnani et al., 2023) leem artefactos de alta frequência e do
autoencoder. [M19] Uma saída de 64×64 que passou por recuperação de grade, redução de cores e remoção de
fundo já não os tem. Testá-las numa saída pequena e concluir "não é difusão" seria um erro de método.

## 5. Inferência por invariantes numéricos

A técnica que mais rendeu nesta pesquisa não precisa de chave: procurar **números estranhos** no contrato
e nos preços e perguntar que máquina os produz.

1. Juntar os números de fontes independentes: escalões de preço (256, 341, 512; 128, 170, 256; 85, 113,
   168; 42, 56, 85), a tabela de candidatos por tamanho (64, 49, 36, 25, 16, 9, 16, 4, 1) e os tetos por
   proporção (512×512, 688×384, largura 792, altura 688).
2. Procurar a forma comum: 256, 341 e 512 são 1024/4, 1024/3 e 1024/2; os outros escalões são esses a
   dividir pela grelha (1/2 para quatro quadros, 1/3 para oito direções numa grelha 3×3, 1/6 para os
   tiles). O produto *grelha × lado máximo* fica entre 245 e 256 para as grelhas de 3×3 a 8×8.
3. Testar contra tabelas públicas que poderiam explicar os números, **incluindo as que não devem
   coincidir**: das quatro tabelas de resolução do Gemini, só a de dez proporções (a do "3.1 Pro Image")
   dá exatamente 792 e 688 quando dividida por 2; a do Gemini 2.5 não dá.
4. Registar o que não encaixa: o caso de 85 px (4×4 em vez de 3×3) e o facto de nenhuma regra única de
   margem reproduzir todas as linhas. Uma anomalia escrita vale mais do que um modelo que a esconde.
5. Escrever a previsão que a confirmaria ou refutaria com dinheiro: sonda S06 (64, 16 e 4 candidatos a
   32, 85 e 86 px; metadados das imagens).

O resultado é uma inferência forte sobre a **forma** (uma tela de ~1 MP a escala inteira, fatiada) e um
indício sobre o **fornecedor** — não uma prova. Outro gerador com a mesma tabela de proporções daria os
mesmos números.

## 6. Armadilhas que esta pesquisa encontrou

- **Nomes comerciais** — "Pixflux" não prova FLUX; a página da documentação chama-se `create-image-flux`,
  o que continua a ser um nome.
- **O fornecedor diz** — o `llms.txt` do site afirma que a plataforma usa modelos próprios; o catálogo diz
  "Powered by MiniMax H3" numa ferramenta. As duas coisas podem ser verdade; nenhuma é uma medição.
- **SDK desatualizado** — os exemplos em Python da especificação v2 usam métodos que o pacote publicado
  não tem.
- **Imagens promocionais** — escolhidas e possivelmente retocadas; medem o melhor caso de uma versão
  antiga, não o serviço de hoje.
- **A ausência de metadados** — nenhuma imagem tinha C2PA, EXIF ou texto. Isso diz que o pipeline
  reescreve o PNG; não diz que gerador o fez.
- **Recomendações que se contradizem** — o relatório de 24/10 pediu que um zero explícito na força da
  imagem inicial fosse enviado como zero; o contrato diz que o mínimo é 1. Só a leitura do contrato
  resolve; a correção está no [dossiê](DOSSIE.md#forja).
- **Viés de confirmação** — procurar só a tabela que coincide. Por isso o script testa todas e o JSON
  guarda as que falham.

## 7. Manter isto vivo

| Quando | O quê | Comando |
| --- | --- | --- |
| Antes de qualquer gasto ou mudança no adaptador | Recolher, comparar o contrato e conferir a Forja | `coleta.py`, `contrato.py --previous contrato-2026-10-26.json` |
| Quando o hash da especificação muda | Rever `tools/forja/backends/pixellab_api.py` até `forja_conformance` dar zero divergências | `contrato.py` |
| Quando aparecem saídas novas (sondas ou uso real) | Medir com a mesma régua | `forense.py` |
| Antes de declarar uma hipótese resolvida | Uma sonda com regra de decisão escrita | [protocolo](PROTOCOLO-SONDAGEM.md) |

## 8. Fontes do método

| ID | Fonte |
| --- | --- |
| M01 | Chikofsky e Cross, "Reverse Engineering and Design Recovery: A Taxonomy", IEEE Software 7(1), 1990 — [resumo da Georgia Tech](https://sites.cc.gatech.edu/reverse/bibliography/terminology.html) |
| M02 | [Clean-room design](https://en.wikipedia.org/wiki/Clean-room_design) |
| M03 | [Diretiva 2009/24/CE (EUR-Lex)](https://eur-lex.europa.eu/eli/dir/2009/24/oj) |
| M04 | [Decreto-Lei 252/94 (Diário da República)](https://diariodarepublica.pt/dr/detalhe/decreto-lei/252-1994-625995) |
| M05 | [Processo C-406/10, SAS Institute (Curia)](https://curia.europa.eu/juris/liste.jsf?num=C-406/10) |
| M06 | [Diretiva (UE) 2016/943 (EUR-Lex)](https://eur-lex.europa.eu/eli/dir/2016/943/oj) |
| M07 | [Decreto-Lei 110/2018, Código da Propriedade Industrial](https://diariodarepublica.pt/dr/detalhe/decreto-lei/110-2018-117279941) |
| M08 | [Lag (2018:558) om företagshemligheter (Riksdagen)](https://data.riksdagen.se/dokument/sfs-2018-558.html) |
| M09 | [18 U.S.C. § 1839](https://www.law.cornell.edu/uscode/text/18/1839) |
| M10 | [17 U.S.C. § 1201](https://www.law.cornell.edu/uscode/text/17/1201) |
| M11 | [Sega v. Accolade](https://en.wikipedia.org/wiki/Sega_v._Accolade); [Sony v. Connectix](https://en.wikipedia.org/wiki/Sony_Computer_Entertainment,_Inc._v._Connectix_Corp.) |
| M12 | [Bowers v. Baystate](https://en.wikipedia.org/wiki/Bowers_v._Baystate_Technologies,_Inc.) |
| M13 | [Van Buren v. United States (2021)](https://www.supremecourt.gov/opinions/20pdf/19-783_k53l.pdf); [hiQ v. LinkedIn (2022)](https://cdn.ca9.uscourts.gov/datastore/opinions/2022/04/18/17-16783.pdf) |
| M14 | [Google v. Oracle (2021)](https://www.supremecourt.gov/opinions/20pdf/18-956_d18f.pdf) |
| M15 | [Tramèr et al., 2016](https://arxiv.org/abs/1609.02943); [Carlini et al., 2024](https://arxiv.org/abs/2403.06634); [Oliynyk et al., 2023](https://arxiv.org/abs/2206.08451) |
| M16 | [OWASP WSTG, recolha de informação](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/01-Information_Gathering/README); [RFC 9162](https://www.rfc-editor.org/rfc/rfc9162) |
| M17 | [Fowler / Thoughtworks, "From Black Box to Blueprint"](https://www.martinfowler.com/articles/black-box-to-blueprint.html) |
| M18 | [Ribeiro et al., CheckList, 2020](https://arxiv.org/abs/2005.04118) |
| M19 | [Yu et al., 2019](https://arxiv.org/abs/1811.08180); [Corvi et al., 2023](https://arxiv.org/abs/2211.00680); [Ricker et al., AEROBLADE, 2024](https://arxiv.org/abs/2401.17879); [Asnani et al., 2023](https://arxiv.org/abs/2106.07873) |
