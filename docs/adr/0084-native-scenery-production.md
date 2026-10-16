# ADR 0084 — Cenários nativos em camadas e revisão física

Estado: aceito pela solicitação explícita do dono de concluir as pendências
da arte aprovada, com acesso inferior, porto, lago e rio (16/10/2026).
Complementa a ADR 0081 e a autorização de editar art/ desta tarefa.

As novas fontes são reconstruções criativas separadas com imagegen. A exportação
usa Pillow, já fixado nas ferramentas, para recorte, amostragem inteira nearest,
alfa binário, redução de paleta sem dithering e divisão lossless em módulos.
Não há dependência adicional no jogo.

As receitas de variação compartilham imagens. A galeria Godot verifica a escala
real dos personagens existentes, pisos nas faixas canônicas, passagens bidirecionais,
vãos e estados construído/vazio. Construções funcionais ficam fora do parallax.
O controlador de caminhada é ferramenta de revisão, separado da simulação.

Os planos naturais substituem os fundos dos oito biomas via o contrato existente
de SceneryArt. Os sítios e terrenos funcionais da campanha permanecem ligados à
simulação. Os novos prefabs de água não decidem as questões de localização e
mecânicas que o dossiê mantém em aberto.

Um job explicitamente limitado ao ramo de produção de cenários pode versionar
as exportações e os resultados da revisão nesse ramo. A main recebe alterações
somente pela PR após os portões completos. O job não publica nem altera a main.
