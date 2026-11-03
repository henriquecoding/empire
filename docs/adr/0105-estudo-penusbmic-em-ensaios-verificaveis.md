# ADR 0105 — Estudo Penusbmic em ensaios verificáveis

- Estado: aceite no âmbito da implementação pedida pelo dono
- Data: 2026-11-03
- Tarefa: [FORJA-19](../backlog/FORJA-19.md)
- Complementa ADRs 0098, 0100, 0101, 0102 e 0103. Não depende do PR de animação nativa FORJA-18.

## Problema

O estudo recebido propõe conferir mãos/objetos, atuação facial, apoio e efeitos por ação; explorar somente
designs em aberto; provar cenas pequenas e repetir ensaios com as mesmas condições. Um relatório ou prompt
isolado não oferece um fluxo executável nem impede que revisão vazia pareça validação concluída.

## Decisão

Conservar o estudo original, sua cobertura e transcrições. Indexar as propostas com fontes e hash, e incluir
o método nos prompts existentes, subordinado ao conceito e às decisões do dono.

Acrescentar exportação por ação de `.aseprite`, conservando fonte, direções, repetição declarada, tempos,
canvas e pivô. O trim é de armazenamento: cada imagem é reconstruída e comparada com o render da fonte.
Separar corpo e VFX somente por camadas explicitamente indicadas. Não aceitar esconder anatomia conhecida.

Acrescentar ensaio HTML local com evidência por quadro/ação, vinculada ao manifesto. Critérios incompletos
ficam pendentes. Objetos partilhados usam dimensões autorizadas, nunca proporção da tela do personagem.
Estados faciais dependem da autoridade e de decisões declaradas; a ferramenta não autentica o decisor.

Fixar receita de autoria com entrada/estado/câmara registrados. Comparações exigem a mesma timeline.
Aplicar janelas de efeito por região/intervalo à revisão e à correção temporal, sem estender a proteção
ao resto da animação nem transportar o efeito ao quadro seguinte.

Variantes limitam-se a designs em aberto; pilotos de cenário conservam a escala do ator, três planos,
oclusão e dia/noite. São ferramentas de revisão, não geração de arte. Sem novas dependências.

## Limites e validação

Hashes atestam integridade, não autoria nativa, biomecânica ou qualidade artística. Um `pass` é evidência
declarada; `release_ready` permanece falso. A prévia de autoria não executa a simulação Godot. A cadeia,
`forja entrega`, testes de integração e aprovação do dono continuam necessários para publicar assets.

Testes usam fontes sintéticas e cobrem reconstrução após trim, tempos não uniformes, direção reversa,
metadados adulterados, evidência ausente, rosto, mãos, objeto partilhado, efeitos, replay e planos de cena.
As rotas antigas continuam cobertas pela suíte da Forja; os portões e a suíte do jogo protegem o restante.
