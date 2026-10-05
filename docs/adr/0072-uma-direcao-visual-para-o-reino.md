# ADR 0072 — Uma direcao visual para o reino

Estado: implementada; validacao registada no PR.

O dono pediu gerar e implementar a renovacao dos personagens, sprites e cenarios,
considerando o visual existente amador. Confirmou a direcao das novas referencias
(3–9), aprovou expressamente as criaturas da Podridao e acrescentou a paisagem
(10), com lago, castelo-carvalho e telhados verde-azulados. Este pedido autoriza a
edicao de art/ para esta tarefa, sobrepondo-se a regra geral 9 de AGENTS.md.

## Decisao

Preservar fontes e originais anteriores. Guardar as novas fontes em
art/source/renewal e produzir atlas, mascaras, emissoes e sprites isolados com
`tools/export_renewal.py`. A preparacao apenas recorta, dimensiona, fixa a base dos
pes e empacota; a criacao visual usa geracao de imagem com as referencias do dono.
Os PNG sao escritos atomicamente e verificados antes de substituir o export.

RenewalArt resolve os novos perfis. OriginalArt continua a disponibilizar os
originais arquivados. Os protagonistas e companheiros seguem os desenhos
confirmados: Monarca corpulento, Nia de cabelo encaracolado e dois machados,
Imperador Arqueiro encapuzado. As sete criaturas partilham madeira apodrecida,
musgo, sombras ameixa e olhos ambar. O combate conserva as suas poses, direcao,
golpes e sombras. Atlas comuns mantem o desenho dos atores agrupavel.

O reino cresce da fogueira apagada para tendas, povoado, vila, vila fortificada e
castelo-carvalho. Os novos sprites nao introduzem obras antes da fundacao. A
floresta funcional da ADR 0070 usa as novas especies, com copas despidas de inverno,
cor de outono, marca de abate e cepo. A simulacao continua a decidir o que existe.

O fundo usa uma paisagem natural, sem uma cidade falsa preconstruida. Plano
atmosferico, vegetacao intermedia e chao continuam separados e sujeitos a luz.
O menu mostra os retratos de referencia e os controlos num painel legivel. O HUD
separa recursos e extras em linhas, com caixas limitadas para impedir sobreposicao.

## Limites e verificacao

As caminhadas usam quatro poses, nao ciclos completos de todos os movimentos.
Golpes, dano e morte continuam animados pelo sistema de poses existente. A direcao
foi confirmada; isso nao equivale a aprovacao final individual de cada asset. O
inventario gerado distingue perfis novos, arquivo e lacunas restantes de unidades
especializadas e obras menores. Nao se alteram dados de balanceamento nem saves.

O export tem verificacao de hashes e equivalencia byte a byte. Os testes conferem
frames nao vazios, base dos pes, limites do atlas, escala relativa, emissoes e
progressao da sede. A suite existente cobre a floresta e o ciclo de construcao.
Capturas de desktop, janela compacta, dia e noite devem acompanhar a revisao.
