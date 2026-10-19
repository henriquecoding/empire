# Floração individual — raiz, desenho e relógio por planta

Requisito do autor: cada flor cresce uma a uma, em ordem aleatória, com aparência orgânica. [Direção e diagnóstico completos](research/2026-10-19-character-animation/historico/PESQUISA-E-PROPOSTA-SOMBRA.md). [Fontes e limites biológicos](research/2026-10-19-character-animation/FONTES-E-APLICACAO.md).

## O problema corrigido

Na V13, `flowers.cjs` remapeava verticalmente uma imagem pronta do campo em torno do chão. Os atrasos eram por faixas de dez pixels. Isso comprimia caules, folhas e pétalas juntos e produzia a impressão de plantas deitadas levantando. Não era crescimento individual nem animação de abertura de pétalas. O corte horizontal de frente/fundo ainda podia separar partes da mesma planta.

A unidade do efeito passa a ser uma planta completa com raiz, espécie, tamanho, camada, sequência e relógio. A planta cresce por desenhos sucessivos; o campo é a composição dessas plantas.

## Desenhos e invariantes

1. Broto aparece acima de uma raiz fixa.
2. Caule se alonga e folhas se distinguem.
3. Botão ganha forma; depois mostra a cor das pétalas.
4. Pétalas abrem mudando a silhueta; o caule não precisa continuar alongando.
5. Flor assenta; pequenos movimentos de manutenção são opcionais.
6. Saída usa desenhos próprios de folhas/pétalas cedendo e desaparecimento.

Não usar escala vertical da flor pronta, rotação do conjunto em torno da raiz ou crescimento ao contrário como substitutos dessas fases. A raiz, a identidade e a posição não mudam no meio da vida. O murchamento não precisa ser igual entre espécies.

Criar poucos tipos reconhecíveis, tamanhos baixos/médios e algumas plantas altas. Uma variante de altura exportada do mesmo desenho não é uma nova espécie nem nova sequência autorada. Na V15 são três espécies, três alturas, oito estágios de crescimento e seis desenhos de murchamento por variante; o primeiro desenho de murchamento duplica a flor aberta e o relógio usa os cinco seguintes na saída.

## Agenda individual

Sortear **uma vez por ativação**: composição, ordem de nascimento, intervalos, espécies, alturas e durações. Não sortear por quadro. Embaralhar a ordem das posições evita uma onda regular esquerda/direita. Cada início é distinto, mas os crescimentos se sobrepõem: a segunda nasce enquanto a primeira ainda abre.

Modelo de dados mínimo, independente de engine:

```text
planta: id, raiz_x, raiz_y, camada, variante,
        inicio_ms, crescimento_ms, murchar_ms, saida_ms
jardim: id_ativacao, instante_inicial, lista_estavel_de_plantas
```

Avaliação sem novos sorteios:

```text
antes de inicio_ms: invisível
entre inicio_ms e conclusão do crescimento: estágio do crescimento
até murchar_ms: flor aberta
durante saida_ms: estágio próprio de murchamento
depois: invisível
```

Exigir `murchar_ms >= inicio_ms + crescimento_ms` na agenda válida. O estágio depende do tempo absoluto desde a ativação, não do número de chamadas de desenho. Pausar ou variar o FPS não pode gerar outra planta. A sequência de amostras pode saltar um estágio em FPS baixo; isso não autoriza alterar a agenda.

Os valores V15 estão no [jardim padrão](research/2026-10-19-character-animation/evidencias/v15/jardim-padrao.json): 28 plantas, inícios após o apoio do corpo, intervalos de 90–170 ms, crescimento de 720–1400 ms, murchamento começando entre 8350–9450 ms e saída de 650–1250 ms. A prévia amostra a cada 80 ms; por isso esses intervalos distinguem os nascimentos nessa prévia. Não prometer um nascimento por frame em qualquer FPS.

Esses números são parâmetros do demonstrador visual de 12 segundos. Não redefinem duração, área, cura ou persistência da habilidade no jogo.

## Composição e profundidade

Distribuir grupos com espaços vazios e variação de altura. Preservar leitura de mãos, cabeça e corpo sentado; pontos claros podem guiar a atenção sem cobrir tudo. Evitar fileiras, simetria perfeita e plantas todas iguais.

Classificar a **planta inteira** como frente ou fundo pela raiz e posição de chão. Renderizar campo de trás, corpo e campo da frente. Não recortar o caule ao cruzar uma linha horizontal. Uma planta à frente pode ocultar parte do corpo, mas não deve nascer sobre o rosto ou parecer presa à roupa.

A composição V15 tem 160×96, pivô `[80,94]`, corpo 80×80 em `[40,16]` e campo 160×40 em `[0,56]`, pivô local `[80,38]`. São coordenadas de uma demonstração, não uma nova escala do personagem. Cada desenho de planta usa célula 24×28 e raiz local `[12,25]`.

## Adaptar ao Empire

O [relógio CJS preservado](research/2026-10-19-character-animation/evidencias/v15/jardim.cjs) é um demonstrador offline com gerador próprio. Serve para reproduzir a agenda histórica; não é a política de RNG da engine.

No jogo, obter a variação visual por `RngService` e fluxo `visual`, que é livre e não participa da simulação/save. Para QA, injetar uma agenda fixa como a preservada, ou usar um mecanismo determinista já oferecido pelo serviço, com chave estável. Não prometer que `visual` reproduz o jardim pela semente do mundo; não consumir `world`/`combat` para decorar a cura.

O `jardim.gd` entregue no ZIP cria sprites e escolhe uma semente fora desse contrato. Antes de integrá-lo, adaptar o relógio à apresentação, tipar o código e ligar início, pausa, interrupção e saída ao estado já existente do personagem. Para milhares de plantas de cenário, seguir o batching da Asset Bible; 28 sprites num demonstrador não autorizam um Node por tufo em todo o mundo.

Se não estiver decidido o que fica depois de interromper a habilidade, registrar a pergunta em `docs/QUESTIONS.md`. A arte não decide persistência ou efeito de cura. Somente sinais do catálogo podem ser conectados; marcadores do JSON não são eventos implementados.

## Verificar

- Raiz opaca no mesmo ponto em todos os estágios; nenhuma planta desloca ou muda de tipo durante a vida.
- Inícios distintos e ordem embaralhada; sobreposição de fases sem brotar o campo inteiro de uma vez.
- Agenda fixa produz as mesmas plantas independentemente da frequência de renderização.
- Camadas recompostas coincidem com a cena de referência; corpo não recebe floração apenas num arquivo separado.
- Testar reinício, pausa, conclusão e interrupção na engine; documentar o estado final conforme a regra do jogo.
- Revisão visual em 1× e em movimento: a flor muda de forma e as pétalas abrem, sem parecer um cartão girando.
