> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 8. Direções, pivots e camadas

A apresentação principal deve funcionar virada à direita e à esquerda. A comparação incluirá mão da arma, perfil do rosto, aljava, escudo e bandeira.

O runtime atual usa espelhamento. Se uma assimetria exigir arte própria para cada lado, exportar duas direções só resolverá a autoria: a seleção da direção também precisará de ligação na apresentação do jogo. Essa diferença deve ficar documentada.

O pivot é o contato central dos pés no frame de referência. Ele permanece fixo nas tags. Na queda, a extensão visual muda; a origem do personagem não deve saltar.

Camadas de autoria propostas:

- body: torso e membros.
- head/face: identidade e expressão.
- weapon/shield: equipamento móvel.
- cloth: capa, bandeira e tecido relevante.
- crown: destacável quando a regra pedir.
- fx: arcos de ataque, notas, sinais e vegetação, exportados separadamente quando apropriado.

Pontos de referência por quadro: mão da arma, origem de projétil, cabeça, mão de transporte e origem de efeito. Os dados precisam dizer se são coordenadas locais do frame ou offsets em relação ao pivot.

