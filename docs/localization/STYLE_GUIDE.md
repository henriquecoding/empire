# Guia de estilo de localização

> *"Um jogo com cem palavras localiza-se por 200 €."* (§27) O humor está nas caras e a sinalética é entalhada —
> por isso o Empire quase não tem texto. Este guia existe para que o pouco que tem seja consistente em todos os
> idiomas, e para que nunca haja uma frase montada no código.

## 1 · Onde vive o texto

| Ficheiro | O quê |
|---|---|
| `data/i18n/strings.csv` | **Todas** as frases do jogo: coluna `keys` + uma coluna por idioma (`pt_PT`, `en`, …). O Godot importa-o como tradução; as colunas `_context`, `_max_chars` e `_notes` são ignoradas pelo importador (verificado em Godot 4.6) |
| `docs/localization/GLOSSARY.csv` | A terminologia: termo PT, termo EN, id interno, género, plural, "não traduzir" |
| `docs/content/NAMES.md` | Gerado: todos os nomes de conteúdo lado a lado |
| `.tres` | **Nunca** texto visível — só `display_key` (§44) |

`tests/data_test.gd` chumba se uma `display_key` não existir em `strings.csv`, se faltar PT ou EN, ou se um texto
passar o seu `_max_chars`.

## 2 · Idiomas

Do §27, pela ordem de prioridade:

| Idioma | Locale Godot | Quando | Nota |
|---|---|---|---|
| Português de Portugal | `pt_PT` | dia 1 | a língua de origem |
| Inglês | `en` | dia 1 | inglês dos EUA; loja incluída |
| Chinês simplificado | `zh_CN` | dia 1 | precisa de fonte CJK própria — secção 7 |
| Russo | `ru` | dia 1 | |
| Português do Brasil | `pt_BR` | dia 1 | "fá-lo tu" (§27); é outra coluna, não uma variante do `pt_PT` |
| Espanhol (Espanha) | `es` | dia 1 | cobre razoavelmente a América Latina |
| Alemão · Francês | `de` · `fr` | pós-lançamento | |
| Japonês · Coreano | `ja` · `ko` | se vender bem | exigem qualidade de tradução |

**A página da loja localiza-se nos oito idiomas no dia em que é publicada** — vale mais do que o jogo localizado
(§27, §36).

## 3 · Chaves

- `UPPER_SNAKE`, com o prefixo do tipo (NAMING_BIBLE §5): `UNIT_ARCHER`, `UI_PAUSED`, `CAPTION_NIGHT`.
- Uma chave, um contexto. Se a mesma palavra aparece em dois sítios com sentidos diferentes, são duas chaves.
- `_context` diz ao tradutor **onde** o texto aparece; `_max_chars` diz quanto cabe. Os dois são obrigatórios em
  texto novo.

## 4 · Marcadores — nunca concatenar

A regra do §27: *"Nunca componhas frases por concatenação (`"Dia " + n`). Usa sempre a chave inteira com
placeholder."*

| Situação | Como | Exemplo |
|---|---|---|
| Um marcador | `%d` / `%s` com o operador `%` | `DAY_N` = `Dia %d` → `tr("DAY_N") % day` |
| Dois ou mais | **marcadores com nome** e `String.format` — a ordem pode mudar por idioma | `UI_SLOT_DAY_N` = `Dia {day} · {people}` → `tr("UI_SLOT_DAY_N").format({"day": d, "people": p})` |
| Plural | duas chaves (`CURRENCY_COIN` / `CURRENCY_COIN_PLURAL`) até haver necessidade real de regras de plural por idioma — aí, ADR para passar a `tr_n` | — |
| Género | nunca montar artigo + nome; a frase inteira é uma chave. O género de cada termo está no glossário | — |

O GDScript não tem marcadores posicionais (`%1$d`); por isso, dois marcadores levam sempre nome.

## 5 · Tom e registo

| | PT-PT | EN |
|---|---|---|
| Ortografia | Acordo Ortográfico de 1990, norma europeia | inglês dos EUA |
| Tratamento | **tu** — "Escolhe o teu povo", como o dossiê fala contigo | imperativo direto — "Choose Your People" |
| Maiúsculas em menus | só a primeira palavra — "Novo jogo" | *Title Case* em botões e menus — "New Game"; frases em *sentence case* |
| Legendas de som | entre parêntesis retos, no presente — "[Cai a noite]" | "[Night falls]" |
| Humor | nas caras, não no texto; o texto é sóbrio e curto | idem |
| Números | nunca vida, dano ou recursos em texto no mundo (§07, §24) | idem |

### PT-PT, não PT-BR

O texto em `pt_PT` usa a norma europeia. As diferenças que mais aparecem em jogos:

| PT-PT | PT-BR |
|---|---|
| ecrã | tela |
| guardar (o jogo) | salvar |
| rato | mouse |
| comando | controle |
| ficheiro | arquivo |
| definições / opções | configurações |
| utilizador | usuário |
| equipa | time |
| partilhar | compartilhar |
| carregar (num botão) | apertar |
| tu / o teu | você / o seu |

## 6 · Não traduzir

Os nomes dos povos (até a Bíblia de nomes decidir), o codinome *Empire* (que nunca deve chegar à loja), os dígitos
da semente do mundo, e qualquer termo marcado `do_not_translate = yes` no glossário.

## 7 · Fontes e espaço

- **≥ 12 px de altura de carácter** a 1280 × 720 — é o critério do Steam Deck Verified e a decisão da Fase 0 (§26,
  §38). Uma fonte de pixel art a 8 px reprova.
- O chinês, o japonês e o coreano não cabem numa fonte de pixel latina de 12 px. Precisam de uma fonte CJK de pixel
  com licença aberta (há fontes de pixel CJK sob a licença SIL OFL, por exemplo as da família *Fusion Pixel* —
  **confirmar licença e glifos antes de escolher**, e registar em `THIRD_PARTY_ASSETS.csv`).
- O texto cresce: conta com +30% em alemão e russo face ao inglês. `_max_chars` é medido no idioma mais longo.

## 8 · Como se revê uma tradução

1. O tradutor recebe `strings.csv` (com `_context` e `_max_chars`) **e** o `GLOSSARY.csv`.
2. A coluna nova entra no CSV; o Godot gera o `.translation` ao importar.
3. Passagem de LQA com capturas a 1280 × 720 e no Steam Deck: nada cortado, nada a sair da caixa, glifos certos.
4. `./run_tests.sh` — o teste de limites de caracteres cobre todos os idiomas presentes.

## Parte XIII — 1 280 palavras novas, e o tom de cada bloco

> Fonte: §75, §76, §77, §79. A §27 dizia que o jogo quase não precisava de idiomas; passa a dizer que **precisa de
> mil e trezentas palavras**, e continua a ser um argumento de venda. Todas vivem em `data/i18n/strings.csv`.

| Bloco | Chaves | Palavras (PT-PT) | Tom |
|---|---|---|---|
| As doze ofertas | `OFFER_*` | 55 | Nunca ameaça, nunca explica, nunca trata por vós. Oito palavras no máximo. Se soar a vilão, reescreve-se até soar a funcionário. |
| Os nove títulos e feitos | `TITLE_*`, `FEAT_*` | 34 + 28 | Descritivos, não heroicos: "O Que Ficou", não "O Bravo". O ordinal acrescenta-se em código. |
| As dez leis de capítulo | `CHAPTER_LAW_*` | 311 | Diz o que acontece, nunca porquê. Nenhuma começa por "aqui é costume". |
| Os dez habitantes | `CHAPTER_WHO_*` | — | Descrição, não fala. O habitante cumpre a lei e nunca a justifica. |
| Os doze diários | `JOURNAL_TITLE_*`, `JOURNAL_BODY_*` | ~900 | 60 a 90 palavras cada. Uma decisão humana, e nada explicado. Se um precisar de 200, está a explicar. |

### O que não se traduz

As canções. Vinte a quarenta segundos, sem letra traduzível — sílabas, vocalizos, ou palavras tão poucas que não
custam localização (§27, §81). As chaves `SONG_*` em `chapters.csv` são **identificadores de pista**, não texto:
não entram em `strings.csv` e não vão para tradução.

### A régua

O controlo de qualidade da escrita não é automático — não há teste que apanhe prosa morna (§84). O único que
existe é o espécime: **se um fragmento novo não aguentar a comparação com o diário 9 da §79, reescreve-se.** É
trabalho de uma tarde por ato.
