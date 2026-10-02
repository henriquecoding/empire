# ADR 0045 — Ataque manual e habilidade de classe

- **Estado:** implementado para o pedido de 01/10/2026; parâmetros novos continuam propostos em Q-184.
- **Problema:** o combate aplicava a rotina das tropas ao corpo controlado; não havia gesto de ataque, a marca confundia-se com a flecha e o Bardo partilhava o relógio da arma com o canto.

## Decisão

A intenção ATTACK entra no início do tick, ligada ao id do corpo. PlayerStrike escolhe o primeiro inimigo à frente, vivo, dentro do alcance e de uma faixa atingível. A resolução ocorre depois do movimento; uma mira válida acerta sem o sorteio das tropas. O dano passa pelo lote comum do CombatSystem, incluindo morte, moedas e feitos. O Arqueiro evoluído conserva a perfuração da coluna. As tropas conservam seleção, precisão e combate automático.

Um gesto pode ficar pendente apenas pela tolerância declarada no CSV. Spam não ignora o intervalo da arma. Segurar ataque renova deliberadamente a intenção à cadência. Habilidade usa a borda do botão, ignora repetição do teclado e fica independente do ataque. Pausa limpa a fila; é preciso largar o botão antes de retomar. Troca de corpo rejeita gestos com o autor antigo.

CombatInput usa `_unhandled_input`: botões, menus e escolha de classe recebem primeiro o evento. Teclado F/R, rato esquerdo/direito e comando RB/RT (R1/R2) usam o mesmo caminho. CombatBar mostra botões clicáveis, prontidão e recarga. A mira indica direção, alcance e alvo. CombatView desenha arco de golpe, rasto de flecha e canto sobre as animações existentes, sem alterar assets.

Monarca ataca com a espada e acede à Vigília existente, com o custo, recusa e consequência originais. Arqueiro dispara e marca separadamente. Bardo recebe o ataque curto proposto em Q-184, sem mudar o dano de IA. BardSong serializa um relógio próprio; saves antigos entram com este dicionário vazio. Maestro usa o mesmo relógio para promover ou converter.

## Dados e limites

Todos os parâmetros novos estão em `units.csv` e `_proposed`; os recursos são gerados. Não se adicionam dependências, autoloads, sinais ou migração de save. A apresentação não decide acertos. A tolerância de entrada e o ataque do Bardo são reversíveis; as habilidades e progressão mantêm o dossiê.

## Fundamentação e verificação

A documentação oficial do Godot orienta a ordem de entrada e o tratamento de repetições:
- https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
- https://docs.godotengine.org/en/stable/classes/class_inputevent.html
- https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html

O teste de ataque manual foi executado antes da implementação e falhou pela ausência de ATTACK. Os casos cobrem ausência de ataque automático, direção, alcance após movimento, faixas, aliados, cadência, buffer, pausa, troca de corpo, marca independente, canto durante recarga e IA das tropas. A validação exige suite completa, portões, dados, vistoria e export Web, além da inspeção visual e dos controlos.
