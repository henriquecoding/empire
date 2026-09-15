# Audio Bible

> A direção está no §23 e não se repete aqui: **uma faixa por bioma em 4 *stems* — base, dia, tensão, noite —
> com *crossfade* pelo `GameClock`**; o *stem* de tensão sobe com a proximidade da Podridão, *"o jogador ouve-a
> antes de a ver"*; o **sino da manhã** é o sinal mais importante do jogo; o **aviso do crepúsculo** tem de se
> reconhecer sem olhar para o ecrã; variação de *pitch* de ±8% em tudo o que se repete; **máximo de 24 vozes** com
> prioridade por proximidade da câmara. Este documento é o que falta: barramentos, nomes, formatos, volumes e a
> lista de produção.
>
> Lista de *cues*: [`AUDIO_CUE_SHEET.csv`](AUDIO_CUE_SHEET.csv)

## 1 · O motor

- `AudioStreamInteractive` e `AudioStreamSynchronized`, nativos desde a 4.3. **Sem FMOD nem Wwise** (§23): poupa
  licença e complica menos o *export* web.
- **O áudio ouve eventos, nunca decide nada.** Um `AudioDirector` (camada de apresentação) liga-se ao `EventBus`
  e toca *cues*; a simulação nem sabe que existe som (invariante I1, §40). Cada *cue* da folha diz que evento da
  §46 o dispara.
- Web: **uma** *stream* de música de cada vez (§19, §23).

## 2 · Barramentos

Proposta — um `AudioBusLayout` com estes barramentos, cada um com volume próprio nas Opções:

| Barramento | Leva | Efeitos | Nota |
|---|---|---|---|
| `Master` | tudo | limitador a −1 dBTP | |
| `Music` | os 4 *stems* do bioma | — | *ducking* de −6 dB quando toca um *stinger* |
| `Stingers` | sino, crepúsculo, noite, conquista, sucessão | — | nunca abafado; prioridade máxima |
| `SFX` | mundo, unidades, construção | *reverb* leve no subsolo | as 24 vozes contam aqui |
| `Ambience` | camas de bioma por fase | *low-pass* no subsolo | |
| `UI` | foco, confirmar, voltar, roda | — | nunca posicional |

## 3 · Nomes e formatos

| Tipo | Nome | Formato |
|---|---|---|
| Música | `mus_<bioma>_<stem>.ogg` — `stem` ∈ `base` · `day` · `tension` · `night` | OGG Vorbis, laços com pontos de *loop*, os 4 *stems* com a mesma duração e andamento |
| Ambiente | `amb_<bioma>_<fase>.ogg` | OGG, *loop* |
| *Stinger* | `stg_<nome>.ogg` | OGG |
| Efeito | `sfx_<categoria>_<nome>_<vv>.wav` — **3 a 4 variantes** do que se repete | WAV 48 kHz, importado comprimido quando > 1 s |
| Interface | `ui_<nome>.wav` | WAV |

Os ficheiros vivem em `audio/` (Git LFS: `.ogg` e `.wav`, §69). O nome do *cue* na folha é o nome do ficheiro
sem variante nem extensão.

## 4 · Volumes

Proposta, para afinar com o primeiro *mix*: música a −16 LUFS integrados com picos abaixo de −1 dBTP; SFX de
combate 3 dB abaixo do sino; UI 6 dB abaixo do SFX. **Regra de ouro: o sino da manhã e o aviso do crepúsculo
ouvem-se sempre**, com 300 unidades a lutar.

## 5 · Posição e prioridade

- Efeitos do mundo são posicionais em X (`AudioStreamPlayer2D`), com atenuação a partir de 640 px (um segmento) e
  silêncio aos 1600 px (a largura visível máxima, §19).
- **Limite de 24 vozes** (§23, §63): quando se passa, cai a voz mais longe da câmara com a prioridade mais baixa.
  A coluna `priority` da folha vai de 1 (sacrificável) a 10 (nunca cai).
- Cada *cue* tem `max_instances`: 8 moedas a cair ao mesmo tempo soam como 8; a 9.ª não toca.
- **Variação de *pitch* ±8%** em tudo o que se repete: passos, moedas, flechas (§23). Sem isto, 300 unidades soam a
  metralhadora.

## 6 · Legendas de som

O §26 pede legendas para 8 pistas sonoras — é o que substitui o áudio para quem não ouve. Cada *cue* com
legenda tem a chave na coluna `caption_key`; o texto está em `strings.csv` (`CAPTION_*`):

sino da manhã · A Podridão desperta · A Podridão aproxima-se · cai a noite · uma muralha cedeu · o monarca foi
ferido · o prazo da dívida · um segredo por perto.

## 7 · O que se produz, e quando

| Pacote | Conteúdo | Fase |
|---|---|---|
| **Fatia vertical** | 1 bioma (floresta antiga) × 4 *stems*; sino, crepúsculo, noite; ~35 SFX; 2 camas de ambiente; UI | 2 |
| Demo | + música de título, *stingers* de conquista e derrota, legendas | 4–5 |
| Completo | 6 biomas × 4 *stems* = **24 faixas**, **~80 SFX** (§23) | 6–7 |

**Orçamento (§23, §35):** entre 1 200 € e 4 000 € para um compositor independente, ou 200–600 € em biblioteca
licenciada. **Decide cedo** — a música define o tom das capturas e dos *trailers* tanto quanto a arte. Tudo o que
vier de biblioteca entra em `docs/legal/THIRD_PARTY_ASSETS.csv` com a prova de licença antes de entrar no jogo.

## Parte XIII — o cante, a encomendação e o coro que conta os povos

> Fonte: §76, §78, §81 e a ADR 0017. A §81 orçamenta 44 h, das quais 38 de som: é a maior fatia de áudio do projeto.

### A encomendação das almas — a cerimónia da alvorada

Duas vozes, sem instrumentos, oito segundos, na alvorada (`mus_encomendacao`). Toca quando há **nome novo** (§76) ou
quando há **Amargueiro novo** (§74). A mesma melodia para as duas coisas, e isso é a decisão: *o jogo não distingue
celebração de luto.*

É o que faz dos quinze segundos da Alvorada uma cena em vez de tempo morto. Sem instrumentos por duas razões: custa
uma sessão de gravação em vez de um arranjo, e uma voz seca a cappella sobre silhueta preta é o material de
*trailer* que a §36 pede.

### Uma canção por povo, e o coro do império

Cada povo tem uma canção. Soltar um povo na Colheita (§78) junta a canção dele ao **coro noturno do império, para
sempre**; ficar com ele cala-o. O coro tem tantas vozes quantos povos soltaste: zero vozes é silêncio, seis é uma
polifonia a seis partes que só um jogador em cada muitos vai ouvir alguma vez.

Não há ecrã de estatísticas, não há barra de moralidade, não há aviso. É o mostrador de moral mais barato que o
projeto tem — e é por isso que a §82 lhe acrescentou a redundância visual: **um estandarte por povo solto sobre o
núcleo** (`world_people_banner`), porque para um jogador surdo um mostrador só sonoro não existe.

### O motivo da Podridão

Terceira menor com massa baixa; segunda menor quando a massa passa 400 (`mus_rot_motif`). O jogador aprende a ouvir
quão má é a noite antes de a ver. Coexiste com o indicador visual, e o indicador visual é a própria candeia e não um
ícone (Q-044).

A candeia tem o seu próprio ambiente — `amb_lantern`, o chiar de uma chama — que é a pista de proximidade que o §26
exige sem acrescentar UI.

### As dez canções de capítulo

Vinte a quarenta segundos, **sem letra traduzível**: sílabas, vocalizos, ou palavras tão poucas que não custam
localização (§27, §77). Uma por capítulo, exceto As Alminhas do Cruzamento — esse é o único sem canção, e o silêncio
é a lei a funcionar.

Estão todas em [`AUDIO_CUE_SHEET.csv`](AUDIO_CUE_SHEET.csv) com o carácter de cada uma. Cabem nas 20 h de som
orçamentadas para a §77, e não nas 38 h da §81.

### A voz da Oferta

`sfx_offer_voice`. A música baixa e a candeia sobe de brilho meio segundo antes da frase aparecer. **Nunca ameaça,
nunca explica, nunca trata por vós.** Fala como quem já fez este negócio muitas vezes e não tem pressa — se uma
frase soar a vilão, está errada, e reescreve-se até soar a funcionário.
