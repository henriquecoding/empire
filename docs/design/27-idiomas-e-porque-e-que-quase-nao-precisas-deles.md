# 27 — Localização · novo · Idiomas, e porque é que quase não precisas deles

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A tua maior vantagem competitiva escondida: o humor está nas caras e a sinalética é entalhada em madeira. Um jogo com cem palavras localiza-se por 200 €. A maioria dos indies gasta entre 5 000 € e 30 000 € nisto.

| Idioma | % utilizadores Steam | Quando | Nota |
| --- | --- | --- | --- |
| Inglês | 37,0% | Dia 1 | Obrigatório, incluindo a página de loja |
| Chinês simplificado | 23,9% | Dia 1 | Segundo maior mercado. Sem ele, perdes um quarto do público. |
| Russo | 10,1% | Dia 1 | Barato e de alto impacto em análises |
| Português do Brasil | 3,9% | Dia 1 | Fá-lo tu. É quase de graça e o mercado é leal. |
| Espanhol (Espanha) | 4,2% | Dia 1 | Cobre também a América Latina razoavelmente |
| Alemão · Francês | 3,0% · 2,4% | Pós-lançamento | Mercados com poder de compra alto |
| Japonês · Coreano | 2,9% · 2,4% | Se vender bem | Tolerância a preço alto. Exigem qualidade de tradução. |
| Português de Portugal | — | Dia 1 | Não pelo mercado. Pela mesma razão que escreves este dossiê em português. |


> **Duas decisões de engenharia, agora**
>
> 1. Usa a importação de tradução por CSV do Godot desde o primeiro texto — a 4.6 melhorou-a com suporte para contexto e plurais. Um único strings.csv, uma coluna por idioma. 2. Nunca componhas frases por concatenação ("Dia " + n). Usa sempre a chave inteira com placeholder (DIA_N → "Dia %d") — em japonês a ordem inverte-se, e corrigir isto depois obriga a caçar cada string no código.

A página de loja localizada vale mais do que o jogo localizado: um utilizador chinês que veja a descrição em chinês adiciona à lista de desejos mesmo que o jogo esteja em inglês. Localiza a página de Steam para os oito idiomas no dia em que a publicares (§36).
