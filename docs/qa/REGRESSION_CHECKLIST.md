# Checklist de regressão

Corre-se **antes de cada build partilhada** (playtest, demo, *release*). O automático já correu no CI; isto é o
que só uma pessoa vê. Quinze minutos. Copia para o registo da build e marca.

## 0 · O CI

- [ ] O último *commit* está verde nos cinco portões, na sincronia de dados e no *export* (QA_MASTER_PLAN §1)
- [ ] Nenhum teste saltado sem razão escrita; os saltados apontam para uma Q do `QUESTIONS.md`
- [ ] `docs/design/` regenerado se o dossiê mudou

## 1 · Arranque

- [ ] Arranca em ≤ 4 s até jogável (§63)
- [ ] Primeira execução (`user://` limpo): idioma → consentimento → título, com foco em "Não" na telemetria
- [ ] Continuar abre o *slot* mais recente

## 2 · O ciclo

- [ ] Um dia completo: as 6 fases distinguem-se **sem HUD** (luz, som, comportamento das tropas)
- [ ] Sino no amanhecer; aviso no crepúsculo; ambos com legenda se as legendas estiverem ligadas
- [ ] A Podridão nasce no crepúsculo, vê-se chegar, invoca, recua ao amanhecer, e as criaturas dissolvem-se
- [ ] Noite 1 ganha sem mortes com a defesa inicial (§31)

## 3 · Os dois verbos

- [ ] Largar moeda recruta, constrói, melhora — o contexto escolhe o alvo
- [ ] Largar em contínuo paga vários níveis
- [ ] Assumir troca de classe / entra em passagem; nunca aparece um terceiro verbo
- [ ] Roda do rei abre só com o monarca assumido; os 6 segmentos respondem

## 4 · Save

- [ ] Autosave no amanhecer; 3 *slots* em rotação
- [ ] Gravar a meio da noite e retomar **a mesma noite** (mesma sequência de invocações)
- [ ] Save truncado: o jogo recua para o *slot* anterior e avisa
- [ ] Save da build anterior abre (migração)

## 5 · Apresentação

- [ ] Nenhum parallax treme; a câmara anda em píxeis inteiros (I8)
- [ ] Sombras de contacto em tudo o que toca o chão
- [ ] Tremor de ecrã só na muralha a cair (e no aríete); desligável
- [ ] Nada de texto abaixo de 12 px

## 6 · Dispositivos

- [ ] Comando: todos os ecrãs; glifos certos
- [ ] Teclado: todos os ecrãs
- [ ] Steam Deck: 1280 × 800 com barras de 40 px; 30 fps nas definições por omissão, alvo 60 (§26, §63)
- [ ] Alt-tab e ecrã inteiro ↔ janela a meio da noite

## 7 · Desempenho (rápido)

- [ ] Noite do dia 20 com o maior exército da build: nenhum *frame* acima de 16,6 ms no *profiler*
- [ ] *Draw calls* ≤ 120; nós ≤ 900 (§63)

## 8 · Build

- [ ] Número de versão e `save_version` corretos
- [ ] Telemetria desligada por omissão na build pública (§32)
- [ ] NOTICE.md e créditos atualizados se entrou um asset de terceiros

## 9 · Parte XIII — o que se desafina sozinho

> Os catorze testes de design da §84 correm no `run_tests.sh` e não entram aqui. Estas oito linhas são o que um
> teste automático **não** apanha: prosa, tom, leitura de ecrã e tempo.

- [ ] **A noite lê-se.** A mancha distingue-se do fundo castanho em campo aberto, sem olhar para a candeia (R-16)
- [ ] **Uma luz por ecrã.** Nenhuma fogueira do jogador compete com a candeia à mesma distância (§80)
- [ ] **A frase da Oferta cabe.** Nenhuma das doze passa de oito palavras nem sai do ecrã a 1280 × 800
- [ ] **O prato é um alvo.** Largar uma moeda ao lado da mancha durante o combate não conta como aceitação (§75)
- [ ] **A Dívida não aparece.** Nenhum número, barra, ícone ou linha de texto, em nenhum modo, incluindo os de
      acessibilidade (Q-045)
- [ ] **A cara na casca lê-se como a cara certa** — a do morto, e não uma qualquer (§74, §80)
- [ ] **Os estandartes contam certo.** Um mastro por povo solto, na mesma ordem, e o mastro vazio para o ficado (§82)
- [ ] **Nenhum habitante de capítulo justifica a lei.** Reler as dez linhas à procura de "aqui é costume" (R-18)
