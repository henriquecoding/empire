> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 9. Compatibilidade concreta com o código atual

O estudo anterior consultou o manifesto de renewal e a leitura de arte em OriginalArt/ActorAction no commit indicado na secção 12. As observações seguintes referem-se a esse retrato documental.

### Estado observado no estudo anterior

Nos seis perfis iniciais das duplas, o manifesto atual usa células de **192×192**, com quatro quadros por personagem. As tags são idle 0–0, walk 0–3 e flee 0–3; as durações registradas são 160 ms. A tela de 192×192 inclui transparência: esse número não equivale à altura do corpo visível.

OriginalArt já lê tamanho de frame, foot, regiões, duração e tags. Isso dá uma base para células de dimensões diferentes. Porém, a entrada de renewal tem prioridade: os novos perfis precisam ser ligados ao lugar efetivamente lido pelo runtime.

ActorAction conhece idle, walk, work, attack, hit, flee e die. As ações específicas como tocar, entregar flechas ou marcar não estão todas mapeadas nessa seleção genérica.

### Consequência para o futuro ZIP

O pacote deve trazer arte e metadados compatíveis, com indicação clara do que está pronto para importação e do que requer ligação de evento. A presença de uma tag nova num JSON não comprova que a simulação já a dispara.

O trabalho de integração posterior precisará:

1. Ligar os novos tamanhos e pivots ao manifesto realmente selecionado.
2. Confirmar que cada ação visual corresponde ao estado/evento certo.
3. Sincronizar a saída da flecha e o impacto ao evento de combate, preservando a autoridade da simulação.
4. Tratar ações únicas e loops corretamente.
5. Verificar inversão lateral e camadas de equipamento.
6. Comparar os personagens sobre cenários claros e escuros do jogo.
7. Conferir a visualização no enquadramento normal e em dispositivo pequeno.

Os conceitos não alteram essas ligações e não foram apresentados como arte já integrada.

