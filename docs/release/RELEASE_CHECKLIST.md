# Checklist de lançamento

> O calendário é o do §36 — página no mês 11, demo no 12, Next Fest no 14, lançamento no 28, numa terça-feira — e
> a regra do dia do lançamento também: *"Nada. Está tudo feito há semanas."* Esta lista é o "tudo".

## Antes da página de Steam (Fase 4, mês 11)

- [ ] **Nome final** escolhido e verificado (NAMING_BIBLE §1) — nada de *Empire* na loja
- [ ] Capsules nos cinco tamanhos do §36 (MARKETING_ASSETS) e **o teste da grelha a 120 × 45**
- [ ] Descrição curta ≤ 300 caracteres e descrição longa, **localizadas nos 8 idiomas** (§27)
- [ ] 4 capturas a 1920 × 1080, cada uma com um sistema diferente; a primeira é a panorâmica (§36)
- [ ] *Tags* escolhidas contra os concorrentes reais
- [ ] Etiquetas de acessibilidade preenchidas com honestidade (ACCESSIBILITY_MATRIX §3)
- [ ] *Trailer* de anúncio: jogo real nos primeiros 3 s, sem logótipo à cabeça, 60–90 s (§36)

## Antes da demo (Fases 4–5, meses 12–14)

- [ ] **Build reproduzível**: o CI gera a mesma build a partir da *tag* de *release*; motor fixado em `.godot-version`
- [ ] **Save estável**: `save_version`, escrita atómica, 3 *slots*, migração testada (§62, QA_MASTER_PLAN)
- [ ] ***Crash logs***: o jogo grava o registo dos últimos 600 eventos (§43) e o erro em `user://logs/` e diz ao jogador onde estão
- [ ] **Opções completas**: áudio, vídeo, controlos, acessibilidade, idioma (SCREEN_REGISTER)
- [ ] **Tutorial**: os primeiros 12 minutos do §25 validados com estranhos (R3 do PLAYTEST_PLAN)
- [ ] **Comando**: todo o jogo, todos os ecrãs (A9)
- [ ] **Steam Deck**: critérios Verified (ACCESSIBILITY_MATRIX §2) e PERFORMANCE_MATRIX verde no Deck
- [ ] ***Trailer*** da demo
- [ ] **Capsule** e **capturas** atualizadas com a arte da fatia vertical
- [ ] **Descrição da loja** revista com as palavras dos *playtesters* (pergunta 2, PLAYTEST_FORM)
- [ ] ***Tags*** revistas
- [ ] **Idiomas da loja**: os 8 (§27)
- [ ] **Link de feedback** no menu de pausa e no título (formulário ou Discord)
- [ ] **Aviso de privacidade e telemetria** publicado; telemetria desligada por omissão (LEGAL.md §3)
- [ ] **Créditos** com as licenças de terceiros exatas da versão do Godot usada (NOTICE.md)
- [ ] Build web: cabeçalhos COOP/COEP ou o ramo sem *threads*; texturas ≤ 1024; uma música de cada vez (§19)
- [ ] REGRESSION_CHECKLIST completa na build final da demo

## Antes da 1.0 (Fase 7, mês 28)

- [ ] **Todos os *achievements*** definidos, implementados (GodotSteam) e testados — incluindo os que só se ganham ao dia 30
- [ ] ***Cloud saves*** a funcionar entre PC e Deck
- [ ] **Créditos** finais
- [ ] **Licenças**: `THIRD_PARTY_ASSETS.csv` sem nenhuma linha "por decidir" ou "por arquivar"
- [ ] ***Localization QA*** nos idiomas do dia 1: capturas de todos os ecrãs, nada cortado (STYLE_GUIDE §8)
- [ ] ***Save migration*** de cada versão pública anterior até à 1.0
- [ ] ***Patch pipeline***: *branch* de *release*, *build* por *tag*, *upload* por SteamPipe documentado
- [ ] ***Rollback***: a build anterior fica num *branch* beta da Steam, pronta a repor
- [ ] ***Backup***: repositório (com LFS) com cópia fora do GitHub; saves de teste arquivados
- [ ] ***Release notes*** escritas para jogadores, não para programadores
- [ ] **Processo de suporte**: onde chegam os relatos, em quanto tempo se responde, como se pede o registo de erros e a *seed*
- [ ] Imprensa e criadores contactados com a build final **4–6 semanas antes** (§36)
- [ ] Dia de lançamento numa **terça-feira**, fora de semana de lançamento grande (§36)
