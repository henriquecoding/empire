# Revisão de personagens e animações

Usar com o [guia](CHARACTER_PRODUCTION_GUIDE.md) e o ticket da personagem. Cada passagem exige evidência própria; aprovação estética pertence ao autor. Uma falha observada deve ser corrigida ou registrada, não ocultada por contagem de quadros.

## Design e escala

- [ ] Regras do dono consultadas antes de produzir e de entregar (`forja regras`, [fonte](OWNER_RULES.md)).
- [ ] Contorno de 1 px intencional, escadas e junções revistas; sem pixels duplos acidentais.
- [ ] Mãos e objeto desenhados juntos: dedos, punho, apoio, peso e oclusão; contacto sozinho não aprova a pega.
- [ ] Expressão conserva olhar, nariz, boca, assimetria, dentes e pelos do conceito.
- [ ] Poção mantém bojo redondo, gargalo, aro, rolha e volume; tamanho absoluto igual no par dos alquimistas.
- [ ] Sem redução com perda usada como entrega; orçamento de rosto/mãos/objeto cabe na grade nativa.
- [ ] Referências e decisão do autor identificadas; versão rejeitada não foi tratada como padrão.
- [ ] Silhueta distingue papel e personalidade; comparação com o elenco na mesma linha dos pés.
- [ ] Prova em 1×, em fundos claros/escuros e na escala pretendida do mundo.
- [ ] Cabeça, mãos, rosto, roupa e acessório permanecem reconhecíveis.
- [ ] Materiais e luz têm hierarquia; clusters não cintilam por ruído de quantização.
- [ ] Tela, caixa opaca, altura útil e ampliação de apresentação estão distinguidas.

## Movimento

- [ ] Poses-chave mostram intenção, apoio e transferência de peso.
- [ ] Caminhada tem duas metades completas e passagem legível de cada perna.
- [ ] Ataque tem preparação, ação e recuperação; braços e arma não somem.
- [ ] Mãos acompanham arco, alaúde, machados ou objeto de entrega durante toda a ação.
- [ ] Sentar/levantar usam quadril, joelhos e apoio; não são compressão da imagem parada.
- [ ] Dança tem perna de apoio, transferência de peso e coordenação de cabeça, tronco e braços.
- [ ] Capa/saia/cabelo acompanham o gesto; rosto e cabeça conservam volume.
- [ ] Loop e emendas entre tags foram vistos; equipamento não troca de mão sem passagem.
- [ ] Espelhos, pausas, sequências invertidas e limitações estão declarados.

## Flores e composição

- [ ] Cada planta tem raiz fixa, identidade e relógio próprios.
- [ ] Crescimento muda caule, botão e pétalas; murchamento tem desenhos próprios.
- [ ] Nascimentos distintos e escalonados; sorteio ocorre uma vez por ativação.
- [ ] Planta inteira pertence à frente ou ao fundo; não há corte horizontal de caule.
- [ ] Personagem e efeito foram vistos juntos; mãos e rosto continuam legíveis.
- [ ] Pausa, interrupção, reinício e fim respeitam o controlador do jogo.

## Arquivos e procedência

- [ ] Ficha visual presa aos pixels e ao conceito; vistas 1×/inteira, fundos claros/escuros e comparação lado a lado.
- [ ] `expect` e cadeia conservados; `forja entrega` passou no âmbito declarado, sem confundir revisão com aprovação.
- [ ] PNGs individuais/atlas/ASE/JSON decodificam e representam os mesmos pixels e tempos.
- [ ] Alpha, dimensões, retângulos, pivôs, tags, loops e sockets conferidos.
- [ ] Não houve recorte/recentralização automática por pose; armas não estão cortadas.
- [ ] Contagem de entradas e rasters distintos separada de espelhos/repetições.
- [ ] Prompt, ferramenta, referência, extração, adaptação e correções declarados.
- [ ] Quantidade real de poses foi contada; o pedido de geração não foi usado como prova.
- [ ] Fonte editável e comandos de reconstrução correspondem ao que foi entregue.
- [ ] Arquivos históricos têm estado explícito e não substituem decisões posteriores.

## Integração

- [ ] Aseprite abriu a fonte; o relato diferencia leitura binária de abertura no aplicativo.
- [ ] Godot importou e exibiu a ação na cena; Nearest, escala, camadas e pivôs conferidos.
- [ ] Importação preserva duração por quadro; divergências da Animation Bible estão resolvidas.
- [ ] Seleção de ação/direção vem dos contratos existentes; marcadores não inventam mecânicas.
- [ ] RNG passa pelo RngService, fluxo nomeado; decoração não altera resultados da simulação.
- [ ] Protótipos do pacote foram adaptados às regras de tipos, camadas e limite de script.
- [ ] Testes exigidos pelo código alterado e portões do projeto passaram.

## Registro da revisão

```text
Versão / commit / autor da revisão:
Evidência 1× e vídeo/loop:
Verificação binária e comando:
Aberto no Aseprite: sim | não
Testado no Godot e cena: sim | não
Design aceito pelo autor: sim | não | com ressalvas
Animação aceita pelo autor: sim | não | com ressalvas
Integração concluída: sim | não
Falhas abertas / próximo passo:
```

Não preencher todos os campos como concluídos porque um teste de pixels passou. O exemplo [V15](research/2026-10-19-character-animation/evidencias/v15/verificacao.json) confirma integridade técnica e mantém explicitamente pendentes aprovação da animação e teste no Godot.
