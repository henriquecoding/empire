# A auditoria de fidelidade na Forja — 27/10/2026 (FORJA-07)

> Pedido do dono (27/10/2026), com o relatório *Forja: por que os sprites perderam o conceito* (revisão 2) e o pacote
> `Forja-Auditoria-Fidelidade-Evidencias-2026-10-27`: *«Quero que implemente isso»*.

A auditoria ([AUDITORIA.md](AUDITORIA.md), cópia exata, sha256 `6ab1ba30…`, o mesmo do manifesto do pacote) explica
porque o Rei, o Escudeiro e o Arqueiro entregues a 27/10 foram rejeitados: uma referência divergente para o arqueiro,
simplificação imposta no pedido, uma redução usada como guia de desenho e novas gerações a partir desse guia — e, por
baixo, uma ferramenta em que a **pureza da amostragem pode ser 1,0 enquanto um traço declarado importante
desaparece**. O [plano de implementação](PLANO-DE-IMPLEMENTACAO.md) e a
[proposta de contrato](CONTRATO-FIDELIDADE-PROPOSTO.json) do pacote também estão aqui, sem mudanças. O contrato que a
Forja lê é o [fidelidade.json](fidelidade.json) (`forja.fidelity/1`), derivado da proposta.

As [fixtures](fixtures/) são os sprites **rejeitados** desta entrega ([STATE.json](fixtures/STATE.json), com os
hashes), só para regressão. A [referência](referencia/referencia-enviada.jpeg) é a prancha enviada pelo dono, a
autoridade desta revisão: um JPEG de várias figuras, não um mestre nativo.

## O que entrou (as cinco etapas de código do plano)

| Plano | O que entrou | Critério de aceite verificável | Teste |
| --- | --- | --- | --- |
| §1 Autoridade antes do pedido | `fidelity.py` e o contrato `forja.fidelity/1`: cada personagem e pose presos a um recorte da autoridade (sha256 dos bytes, caixa), com invariantes, regiões, pinos e candidatos rejeitados pelo hash dos pixels. `plan`/`auto`/`prompt` com `--fidelity --character [--pose] [--mode]`: o recorte vai anexado como conceito; um conceito que não é ele é `reference_conflict`; um candidato rejeitado não entra; `recover_grid` não gera; `edit_approved_master` pede o mestre aprovado; um guia em revisão sozinho é recusado. `constraints.py`: cada linha do prompt com a origem (`contract:`, `palette:`, `explicit_request`, `fidelity:`, `concept`, `compiler_default`); o modo fiel não tem nenhuma `compiler_default` — nem «two tones», nem «12-24 colors», nem o perfil estrito —, e `--max-colors`/`--tones` só entram como decisão dita | o arqueiro de túnica verde é conflito antes de gerar; o pedido fiel leva o recorte e `implicit` vazio | `test_contrato_fidelidade.RequestTest` |
| §2 Grade recuperada ≠ redução | `Grid.origin`: `exactly_measured`, `estimated`, `operator_declared` (conferida contra a ampliação exata medida), `deliberately_reduced` (`--reduce`, ou uma grade dada mais grossa do que a medida) e `unmeasured`. `gridcheck.report` (`snap.grid_report`): período, tamanho recuperado, se cabe na tela, as zonas de escala mais fina (`mixed_scale`), e afirmações separadas sobre a grade e os valores (`pixel_values`, `lossy_input`, `original_colors`). Achados `grid_budget` e `grid_reduced` | a entrada mista de período 2 diz 128×128 contra 16×16 e as zonas finas; uma redução nunca é «recuperação»; o JPEG não afirma as cores | `test_perdas.GridOriginTest` |
| §3 O que a amostragem deita fora | `loss.py`: cada célula lida inteira contra o pixel escolhido — `outside_core`, `minority`, `alpha_discarded`; o que um vizinho tem ou a mistura com ele é `absorbed`; o resto é `erased`, sem limiar global (um olho é uma célula). As células que ficaram vazias continuam nos dados. Achado `erased` no `forge`. A pureza passa a ser medida em todos os métodos (`purity_basis: core`) | o traço de borda e a linha alfa ficam escritos com pureza 1,0; o controlo de célula inteira não | `SamplerLossTest`, `PipelineLossTest` |
| §4 Restrições sem sobrescrita | `signals.py` e `forge --signals` (`forja.signals/1`, preso ao hash dos pixels da imagem): pinos `authorized` aplicados depois do voto e protegidos até ao PNG final (o `guard`); dois pinos de cores diferentes na mesma célula são `layout_conflict` com as duas origens, e nenhum se aplica; sem cor, sem coordenada ou sem autorização, `pending`; regiões com a perda medida dentro (`lost` bloqueia se `required`). `verify --signals` volta a conferir os pinos depois da composição | a ordem não decide o vencedor; um pino que a tela corta fica `lost` e bloqueia | `test_sinais` |
| §5 Revisão com estados separados | `review_state.py` e `forja fidelity`: `runtime`, `declared_feature_preservation`, `identity_and_pose`, `native_master_approval`, cada um com a sua evidência; um candidato rejeitado (no contrato ou no registo) fica `blocked` na identidade mesmo com o runtime a passar; a identidade passa só por uma revisão humana registada desta imagem exata (com observação por aspeto) ou pela aprovação do dono; `--sheet` põe o conceito e o candidato lado a lado, a 1× e ampliado por inteiro | a roupa verde bloqueia a identidade com o runtime em `pass`; um pixel mudado volta a pendente | `ReviewTest` |

O §6 do plano (o piloto artístico do Rei) é desenho e não foi feito: não houve geração nem chamada paga. As
coordenadas das regiões, a caixa útil e os pinos ficam `null`/pendentes no contrato, como a auditoria pediu: não se
inventam por escala da tela.

## A prova

[prova_auditoria.py](prova_auditoria.py) refaz os ensaios da auditoria com a Forja deste ramo e grava
[prova.json](prova.json) e [evidencias/](evidencias/); o `make forja` corre-a e chumba se o JSON mudar sem commit. Sem
rede, sem geração, sem aprovação. Os casos reutilizam origens: não são uma amostra estatística.

| Ensaio da auditoria | Antes (relatório) | Agora |
| --- | --- | --- |
| Amostrador: 6 fixtures × 5 métodos × 2 recuos | a marca some com pureza 1,0 e sem aviso | nenhuma marca apagada fica fora de `loss.erased`; o controlo nunca é perda; a pureza é medida em todos os métodos |
| Pipeline: 6 fixtures, escala declarada e automática | o traço de borda e a linha transparente desaparecem sem achado; a grade de período 2 dá 128×128 calada | `erased` nos dois; `grid_budget` com as zonas finas; a escala 16 sobre uma ampliação 2× é `deliberately_reduced`; uma região declarada com a marca apagada bloqueia |
| Grade: 21 perturbações dos 3 PNG rejeitados | 12/12 exatos; JPEG com grade e sem cor; bilinear tratada a 1× | os 12 continuam exatos; nos 6 JPEG a silhueta volta e `original_colors: not_provable_lossy_input`; nas 3 bilineares `origin: unmeasured` com a mensagem de `--scale` e `--reduce` |
| Autoridade e revisão no contrato real | — | o arqueiro de túnica verde como conceito é `reference_conflict`; os três pedidos fiéis levam o recorte e nenhuma preferência do compilador; os três rejeitados ficam `blocked` na identidade |

As pranchas `evidencias/<personagem>-conceito-e-rejeitado.png` são a revisão lado a lado (`review_state.sheet`) do
conceito e do candidato rejeitado, para mostrar a ferramenta, não novas propostas de personagens.

### O que a implementação mostrou além do relatório

1. **Um JPEG 8× alinhado com os blocos da compressão é uma ampliação *exata*.** Com croma sem subamostragem, cada bloco
   8×8 de uma cor sai de uma cor — outra cor. A grade mede-se exata e as cores não são as originais: por isso o
   relatório separa `exact_upscale`/`pixel_values` de `lossy_input`/`original_colors` em vez de chamar «cópia exata» a
   uma cor mudada (§14.2 da auditoria, levado ao fim).
2. **A escala «conhecida» de 16 das fixtures é uma redução.** As fixtures centrais e a linha são ampliações exatas 2×
   (o traço de 4 px cai na grade de 2): declarar 16 é reduzir. A Forja agora di-lo sozinha (`deliberately_reduced`),
   o que é exatamente o erro do §3.4: uma grade imposta não é a grade da origem.
3. **Os rejeitados não cumprem a paleta mestra.** Contra a paleta do contrato (`empire`), o Rei, o Escudeiro e o
   Arqueiro têm 25–26 cores fora; a sessão anterior conferiu-os contra a paleta extraída deles próprios (auditoria,
   §6). O elenco V15 integrado também não a cumpre. Que paleta é o runtime do elenco é uma pergunta (Q-289);
   `forja fidelity --palette` aceita a decisão.
4. **A prova de 27/10 (FORJA-06) muda um valor:** o plano do arqueiro com só a adaptação em revisão anexada passa a
   `ok: false` — um guia em revisão já não substitui o conceito. A verificação dessa prova continua a passar.

## Limites

- A perda é evidência, não reconhecimento: a Forja não sabe se a cor apagada é um dente ou ruído. Os limiares
  (`MIN_SHARE` 4 % da célula, `NEAR` 0,08 OKLab) estão calibrados nas fixtures sintéticas e nos ensaios do pacote, não
  em pares conceito/candidato aceites pelo dono (Q-287). Numa imagem gerada real há dezenas a centenas de células
  apagadas (o rosto, quase sempre): o achado aponta, a decisão é de desenho.
- `identity_and_pose` e `native_master_approval` só passam pelo que uma pessoa registou. A Forja não tem comando que
  escreva uma revisão de identidade nem uma aprovação.
- As caixas dos recortes são anotações manuais de inspeção (podem incluir chão ou sombra). Recortar a prancha não faz
  do recorte um mestre nativo.
- SSIM, LPIPS e médias globais não entraram como aprovação: a auditoria (§15.2) não dá base para um limiar.
- O `sheet` (prancha animada) ainda não mede a perda por quadro: só o `forge` de uma figura (Q-287).
