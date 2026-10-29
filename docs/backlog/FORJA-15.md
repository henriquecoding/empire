# FORJA-15 — coreografia, animação e bancada de revisão

Estado feito — coreografia, adaptador, cenários locais, exportação e bancada;
          aprovação artística e benchmark pago são etapas de produção.

## Pedido

O dono, em 29/10/2026, pediu implementar a pesquisa densa sobre animações, poses
e cenários na Forja, usando GitHub e Vercel.

## Autoridade

AGENTS.md; [ADR 0101](../adr/0101-coreografia-e-revisao-de-movimento-na-forja.md);
[guia operacional](../art/FORJA_MOVIMENTO.md); CHARACTER_PRODUCTION_GUIDE,
ANIMATION_BIBLE, ASSET_BIBLE e contratos existentes da Forja. Sem alterar
`art/`, `audio/`, balanceamento ou runtime do jogo.

## Entrega

| Item | Implementação | Verificação |
| --- | --- | --- |
| Poses e clips | Geometria, identidade, duração, loop, sockets e regiões separados | JSON inválido, dimensões, contagem, hashes |
| Biblioteca inicial | Estudos de idle/walk/attack/die em 64/80 px | Fases distintas, sem aprovação presumida |
| PixelLab | skeleton-v3/text-v3 com jobs e limites | 80 px, cinco quadros, ordem, submissão ambígua, retomada |
| Movimento funcional | Apoios no mundo, contactos, regiões fixas/transportadas, transições | Deriva, lacuna e informação incerta distintas |
| Cenários | Componentes locais, âncoras, ordem e interações | Zero mudança fora da máscara e hash de origem |
| Pacote portável | Referência, quadros, Aseprite, atlas, SpriteFrames, revisão | Fonte removida, ida/volta e tempo/loop no Godot |
| Bancada web | Comparação a 1×/4×/8×, playback, overlays e observações | Navegador móvel/desktop, hash e encerramento |
| Comparação | Custo por aceito, rejeições, minutos e desconhecidos | Hash alterado e duplicação recusados |

## Limites explícitos

Nenhuma geração paga, desenho aprovado ou instalação de novos sprites. As poses
são estudos que exigem ajuste aos pixels do personagem. Declarações de apoio e
contacto não são detecção automática de anatomia. O pacote Aseprite não separa
uma imagem achatada em roupa, corpo e armas. A bancada não é editor de poses e
não envia pedidos ao fornecedor. ControlNet, modelos temporais e rigs ficam
como alternativas para um piloto posterior, sem dependências novas.

## Verificação reproduzível

`make portoes`; `GODOT=... ./run_tests.sh`; testes web em `tests/web/*.test.mjs`;
`node tests/web/forja-ui.mjs`; build estático e CI do PR. O teste de exportação
no Godot declara skip quando o motor não existe; não se anuncia esse caso como
validação de runtime. A publicação é do site e ferramenta, sem promover arte.
