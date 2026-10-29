# FORJA-12 — auditoria dos cenários de 28/10: os contraexemplos fechados e a ordem do que falta

Estado parcial — A1–A7, a tabela de pixels do Gemini, o mestre pelo registo e o perfil de medidas fechados com testes;
          a ordem 3 a 8 da auditoria por fazer

## Pedido

O dono, a 28/10/2026, com a auditoria *Forja — auditoria e pesquisa para cenários e construções* (base `91d3521`):
*«Corrija isso»*.

## Spec e autoridade

[Auditoria e aplicação](../art/research/2026-10-28-forja-cenarios-auditoria/README.md) (o texto do dono em
[`AUDITORIA.md`](../art/research/2026-10-28-forja-cenarios-auditoria/AUDITORIA.md)),
[FORJA-11](FORJA-11.md), [ADR 0098](../adr/0098-a-forja-desenha-cenarios-pela-regua-dos-atores.md),
[ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md), [Guia da Forja](../art/FORJA.md), AGENTS.md (regras 1,
8 e 9).

## Entrega

| Achado | O que entrou | Evidência |
| --- | --- | --- |
| A1 porta de 2 px | `scene.validate` recusa a largura abaixo de `door_clear_width`; `vaos.opening` mede a largura útil | `test_cenarios_auditoria.OpeningTest` |
| A2 casa suspensa | `estrutura._support`: a estrutura principal tem de tocar no chão; peças soltas contadas | `SupportTest` |
| A3 emenda de cores | `emendas.joint`: alfa e cor, cada um contra o percentil 90 do interior | `SeamTest` |
| A4 estado igual | `emendas.states`: nada fora das zonas e alguma mudança dentro | `StateTest` |
| A5 referência perdida | `scene_plan`: `sent` por referência; `init_image`/`style_image` no PixelLab ou recusa | `TransportTest` |
| A6 estados vazios | o contrato recusa; estado sem zonas avisado | `StateTest` |
| A7 altura +1 | `vaos.opening` conta filas (máximo exclusivo) | `OpeningTest` |
| Tabela do Gemini | `backends/gemini_pixels.json`, `gemini_images.published` | `GeminiPixelsTest` |
| Mestre por registo | `forja estrutura --refs`, `master_state` | `AuthorityTest` |
| Perfil de medidas | `scenery.json` `metrics_profile`; `rule_status` nas verificações | `ProfileTest` |

## Por fazer

A ordem da auditoria, a partir do passo 3:

1. Ligar o contrato à obra: o id de `buildings.csv` e a pegada, a área visual e as saliências, o pivô em todos os
   estados, máscaras semânticas de vãos e apoios por tipologia, encaixes com classe, e a correspondência com
   `SiteStage`/`BuildingSkins` (o que é imagem, efeito ou simulação).
2. Transportar o contrato no Aseprite (slices para base, vãos, apoios e encaixes) e no export, com teste de ida e
   volta — **feito no [FORJA-13](FORJA-13.md)** para o pivot, os vãos, os sinais e as zonas de estado
   (`forja estrutura --aseprite`, `forja ase --scene`); os apoios e os encaixes esperam o passo 1.
3. Consumir os candidatos na galeria Godot que já existe (`tools/native_scenery_review.tscn`, `verify_` e
   `capture_native_scenery.tscn`): Rei e Nia à volta, caminhada nos dois sentidos, dia/crepúsculo/noite com as luzes
   reais, estados, cópias e vizinhos, superfície e nível inferior, 720p e 1080p.
4. O piloto Enramados completo (a forja compacta, a árvore, a família de terreno e o plano de fundo juntos), com um
   mestre por elemento.
5. Os adaptadores de ambiente do PixelLab (tileset lateral, edição por máscara) com a tabela de capacidades por
   endpoint, e o custo por peça aceite num piloto comparativo com teto aprovado.
6. O catálogo de módulos e variantes (superfície 1D, remates, mudanças de material) pelos mesmos critérios.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem aprovação
artística. As medidas continuam propostas (Q-295); a largura da baía de trabalho é a Q-301.

## Verificação

`make forja` (a prova dos cenários com 26 verificações, a suíte e as outras provas sem deriva);
`python3 -m unittest tools.forja.tests.test_cenarios_auditoria`; portões estáticos locais; CI do PR.
