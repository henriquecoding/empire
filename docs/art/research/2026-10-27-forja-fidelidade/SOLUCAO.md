# Solução para recuperar e preservar os personagens na Forja

Plano de execução e provas locais para Henrique e Claude · 27/10/2026

**A solução recomendada é estabelecer um sprite mestre fiel ao conceito na grade final e fazer as correções seguintes por regiões, conservando os pixels desse mestre fora da alteração autorizada.** O desenho precisa ser recuperado antes de ser protegido. Proteger o último resultado rejeitado apenas congelaria a descaracterização.

Este documento complementa o diagnóstico anterior com um procedimento de recuperação, decisões de implementação e ensaios nas funções reais da Forja. A `main` foi reconferida no GitHub: `44e5911c4374107766f94eb4c28144ad80d5abf0`. Nenhuma alteração de produção, deploy ou geração paga foi executada nesta pesquisa.

## 1. Resolver o desenho atual

Há duas etapas com objetivos diferentes. A primeira reconcilia conceito e grade; a segunda conserva o desenho já reconciliado. Elas não podem usar o mesmo ciclo de geração e acabamento global.

| Etapa | Entrada e procedimento | Condição para avançar |
| --- | --- | --- |
| Recuperação | Conceito de autoridade, tela 80×80 para Rei/Arqueiro e 64×64 para Escudeiro; reconstruir massas e traços na grade | Expressão, proporções, materiais e equipamento correspondem ao conceito; revisão ainda explícita |
| Edição local | Sprite mestre nativo, máscara da alteração e regiões protegidas | Pixels externos e protegidos permanecem iguais; qualidade da parte editada é revista |
| Exportação | Candidato revisado em PNG/Aseprite | Pixels, dimensões, offsets, paleta e interpretação de cor preservados |

Se a origem já for pixel art ampliada, recuperar primeiro a escala real, com a redução de cores desativada. O Unzoom do PixelLab trata a recuperação de escala e a redução de cores como controles distintos. Depois se decide a adaptação de desenho. [S01]

Se a origem contiver muito mais detalhes que a tela final, reduzir a imagem é apenas uma primeira aproximação. A expressão precisa ser reconstruída em pixels nativos, comparando olho, sobrancelha, nariz, canto da boca e dentes com o conceito. A pesquisa de Gerstner e colaboradores fundamenta o uso de regiões importantes e restrições por pixel/paleta nessa adaptação, em vez de deixar todas as decisões para uma redução uniforme. Não foi implementado o algoritmo integral do artigo. [S02]

### Procedimento concreto de recuperação

1. Separar a referência de conceito, a adaptação atual e o arquivo final rejeitado. Registrar origem, hash e estado de cada um. A última saída não substitui a referência só por ser mais recente.
2. Montar a silhueta e as massas principais diretamente na tela final. Definir apoio no chão e tamanho do corpo antes de colocar ornamentos. Não esticar o PNG pronto para preencher espaço.
3. Resolver o rosto cedo: contorno da cabeça, olho/sobrancelha, perfil do nariz, sorriso e pelos faciais. Guardar um recorte de referência do rosto na mesma grade. Comparar em 1× e em ampliação inteira.
4. Organizar tecido, pele e metal em rampas por material. Manter as diferenças de família cromática do conceito; qualquer incompatibilidade com a paleta deve ficar visível.
5. Corrigir equipamento com máscara própria, incluindo contatos necessários com mão e braço. Quando um detalhe fino tiver forma e cor conhecidas, usar um reparo determinístico.
6. Registrar a versão revisada como mestre somente quando houver aprovação real. Até lá, usar o estado `adaptation_in_review`. As fixtures desta pesquisa continuam reprovadas.

O método de trabalhar com grandes agrupamentos e refiná-los é compatível com o ensino de Saint11. O autor também distingue ruído de detalhes úteis de um pixel. Para o Empire, olho, dente ou canto da boca precisam de função declarada antes de qualquer limpeza. [S03]

## 2. O que fazer em cada personagem

| Personagem | Recuperação prioritária | Edição posterior |
| --- | --- | --- |
| Rei | Restituir atuação de sobrancelha, nariz e sorriso; manter a família vinho da túnica e a relação entre barriga, cabeça e capa | Lâmina e punho em máscara de equipamento; rosto e roupa conservados |
| Arqueiro | Recuperar perfil, sorriso e pele quente; dar espaço ao corpo e aos braços na tela 80×80 | Separar miolo claro da corda, contorno e oclusão do antebraço; conferir contatos do arco |
| Escudeiro | Reconstruir relação elmo/olho/nariz/boca e silhueta do escudo em 64×64 | Ajustar corpo e equipamento mantendo a expressão; conferir uso do espaço sem aumentar o sprite por escala |

Uma cor inexistente na paleta autorizada não pode ser mantida exatamente e, ao mesmo tempo, pertencer a essa paleta. A solução é propor uma aproximação por material ou uma revisão da rampa, conservando o conflito visível. Um limite arbitrário de 22 cores não resolve essa decisão.

## 3. Fazer a preservação acontecer na composição

O PixelLab documenta edição de partes marcadas por inpainting. Seu tutorial trabalha cabeça e mão em etapas. Isso fundamenta pedir uma mudança por vez, com área de atuação definida. [S04, S05]

Na API de imagens da OpenAI, a máscara orienta o modelo, mas não garante que ele siga seu contorno com precisão completa. [S06] O guia oficial de prompting recomenda recompor a edição sobre o original quando uma região precisa continuar idêntica em pixels. [S07]

A Forja já implementa o mecanismo principal em `inpaint.prepare`, `inpaint.merge` e `compose.compose`. A resposta ampliada deve voltar no tamanho exato; a amostragem usa a escala conhecida; o candidato entra apenas na região autorizada. A recomendação é tornar esse caminho obrigatório para reparos locais e vinculá-lo ao mestre correto.

### Regra operacional

Para cada pixel: fora da máscara, copiar o mestre; dentro da máscara, usar a proposta local, respeitando as proteções. Máscara sobreposta a área protegida deve ser recusada antes do pedido. Retorno de tamanho errado deve interromper a tentativa. Não usar esse erro como motivo para gerar o personagem inteiro outra vez.

Após a composição, repetir a verificação contra o mestre. Um acabamento global posterior pode desfazer a garantia. Em uma edição local de um sprite nativo, o encerramento deve usar verificações somente de leitura e exportação conferida.

### Comando existente: modelo de uso

Os caminhos abaixo são nomes de exemplo para arquivos reais que devem existir. As coordenadas do Arqueiro são as do ensaio, não uma máscara final aprovada. A chamada `inpaint` pode consumir a API configurada; **não foi executada com um gerador real nesta pesquisa**.

```bash
python3 -m tools.forja inpaint arqueiro-mestre.png \
  --mask arco-e-mao.png --protect 38,23,49,38 \
  --method replace --palette empire \
  --change "Repair only the bow and grip inside the mask. Preserve the character design and the light-colored string." \
  --max-calls 1 -o arqueiro-candidato.png

python3 -m tools.forja lint arqueiro-candidato.png \
  --kind royal_80 --palette empire

python3 -m tools.forja aseprite arqueiro-candidato.png \
  --palette empire --pivot 40,78 -o arqueiro-candidato.aseprite
```

O `lint` não substitui a prova externa à máscara, nem aprova identidade. A máscara nativa da CLI usa alfa para marcar a região ou, se totalmente opaca, pixels claros; a Forja converte para a convenção do provedor. Não reutilizar diretamente uma máscara com semântica invertida.

## 4. Resolver a corda: miolo, contorno e cor explícitos

O reparo anterior selecionava miolo e contorno juntos. A maioria preta dominou a decisão. Além disso, `repair.straighten` escreve a cor escolhida somente em `new - line`: os pixels já pertencentes à linha mantêm sua cor. **Acrescentar um parâmetro de cor, sozinho, não corrigiria esse comportamento.**

A implementação proposta precisa:

1. Receber uma máscara específica do miolo e uma cor/família de material declarada; o contorno fica em outra região.
2. Proteger pontos de ligação, madeira, mão e oclusores que não pertencem ao miolo editável.
3. Aplicar a cor a todos os pixels do miolo final, incluindo os que já estavam na linha antiga.
4. Remover segmentos antigos apenas quando houver informação suficiente sobre o fundo. Se a região por baixo estiver encoberta e desconhecida, registrar a inferência ou interromper o reparo.
5. Devolver estado inconclusivo quando seleção ou cor esperada não estiverem definidas; não decidir aparência por maioria.

O protótipo `stroke_solution.py` demonstra a parte de pintura explícita e proteção. Não implementa reroteamento completo da linha nem reconstrução de fundo oculto. Na fixture do Arqueiro, a máscara manual do miolo fica em x=56, y=22…69, excluindo a oclusão do antebraço. O contorno em x=57 permanece protegido.

O ensaio conservou os **30 pixels claros existentes** e preencheu **10 interrupções**, obtendo 40 pixels claros nessa região. Exterior, contorno e oclusores permaneceram iguais. Trata-se de uma demonstração técnica da intenção declarada, ainda pendente de revisão artística; o personagem inteiro continua reprovado.

## 5. Resolver as cores antes de fundir materiais

`materials.apply` e `forja cores` já trabalham com rampas por região, áreas presas, preservação do alfa e provas de alteração local. A solução é usá-los sobre o nativo correto, antes que um mapeamento global tenha eliminado distinções essenciais.

Uma região de pele deve escolher entre tons de pele; uma lâmina, entre tons metálicos. Os controles de paleta do PixelLab podem limitar ou impor um conjunto de cores, mas não identificam por si o material de cada pixel. [S08]

### Prova com o Rei

Foi aplicado um plano somente à região editável da lâmina, com a rampa de demonstração `#A19D9E / #F0F0F0`. Não houve agrupamento automático. O ensaio mudou **26 pixels**, preservando os **826 pixels presos**, o exterior editável e todo o alfa.

O teste também mostrou um caso que precisa bloquear aprovação: a região chamada `blade` sobrepõe 15 pixels das áreas presas, com nove cores fora da rampa metálica. O relatório da Forja registra esses conflitos em `locked_off_ramp`; seu `ok` técnico continua verdadeiro porque as áreas presas foram conservadas.

**Solução para esse conflito:** rever os seletores e separar lâmina, punho e mãos em regiões com autoridade. Não retirar a proteção apenas para obter um relatório limpo. A política de entrega precisa exigir resolução dos conflitos de material além da preservação dos pixels. Neste ensaio, o estado de material permanece pendente.

Também não se deve aplicar filtro de mediana ou desfoque global para obter suavidade. Saint11 descreve correção do ritmo das bordas e alerta para excesso de antialias e banding. Para o contrato atual do Empire, essas ideias orientam o desenho dos agrupamentos; não autorizam introduzir suavização global ou novas cores automaticamente. [S09]

## 6. Recuperação assistida: opções a ensaiar

Para conceitos que ainda precisam da primeira adaptação, há três caminhos. A escolha depende da fonte e da fidelidade observada.

| Caminho | Uso adequado | Estado nesta pesquisa |
| --- | --- | --- |
| Recuperar escala | Pixel art ampliada com grade recuperável; conservar cores antes de decidir rampas | Procedimento documentado; não elimina ambiguidades da fonte |
| Conversão guiada | Conceito mais denso, exigindo uma aproximação inicial | A API PixelLab documenta `fixer` e `init_image_strength` em `/image-to-pixelart`; qualidade no Empire ainda não ensaiada |
| Reconstrução nativa com auxílio local | Expressão ou proporções não sobrevivem à conversão | Caminho recomendado para resolver os traços essenciais antes de congelar o mestre |

O modo `fixer` é um recurso documentado, não um parâmetro já exposto pelo adaptador atual da Forja. Sua integração requer verificar campos e tamanho recebido. [S10] Não há ensaio que permita declarar que ele resolverá sozinho o rosto do Rei.

O piloto deve variar uma coisa por vez e registrar cada retorno. Primeiro obter uma base estática aceitável; depois avaliar seeds, forças ou modelos com as mesmas referências. Não usar aumento de qualidade ou de resolução como prova de preservação da grade nativa.

## 7. Implementação para Claude, em ordem

| Ordem | Arquivos / mudança | Critério verificável |
| --- | --- | --- |
| 1 | `plan.py`, `prompts.py`: autoridade e estado das referências; distinguir recuperação de edição local | Uma referência em revisão ou rejeitada não é chamada de aprovada pelo prompt |
| 2 | `cmd_image.py`, `auto.py`, `review.py`: comparação compartilhada de expectativa/retorno | Tamanhos e grades divergentes produzem pendência explícita nos dois caminhos |
| 3 | Orquestração → `inpaint.py`, `compose.py`: usar o mestre e a máscara na correção local | Rosto/roupa externos à máscara continuam iguais; tamanho errado não dispara redesenho global |
| 4 | `repair.py`, `cmd_equip.py`: separar miolo, contorno e cor da corda | A fixture histórica não perde os 30 pixels claros; casos sem intenção declarada ficam inconclusivos |
| 5 | `materials.py`, `cmd_cores.py`, política de entrega: tratar conflitos de regiões e rampas | `locked_off_ramp` pendente impede aprovação material, mesmo com preservação técnica válida |
| 6 | `verdicts.py`, encerramento: identidade e aprovação real como condições de conclusão | `not_evaluated` não vira entrega final; evidência de arquivo não é apresentada como aprovação artística |

Os nomes de campos e novas condições desta proposta ainda precisam ser integrados; não são opções novas já disponíveis na CLI. Reutilizar as funções existentes evita manter um segundo pipeline de composição em paralelo.

Antes do merge, seguir o fluxo do repositório: testes de regressão que falhem no código anterior, implementação mínima, verificações obrigatórias e revisão do diff. Esta pesquisa não altera `art/`, código de produção ou a `main`.

## 8. O que os novos ensaios comprovam

Os arquivos do pacote usam a Forja atual, não apenas o bloqueio externo do diagnóstico anterior. As entradas são fixtures rejeitadas. As respostas de gerador foram simuladas deliberadamente para incluir uma alteração facial proibida.

| Ensaio | Resultado |
| --- | --- |
| Composição local em Rei, Arqueiro e Escudeiro | Mudança autorizada mantida; rosto e exterior idênticos ao arquivo de entrada |
| Resposta que repete a entrada | RGBA reconstruído exatamente nos três casos |
| Retorno de tamanho errado | Recusado nos três casos |
| Máscara sobre área protegida | Recusada nos três casos |
| Rampa somente na lâmina do Rei | 26 mudanças locais; zero alteração em áreas presas; nove conflitos de material ainda pendentes |
| Miolo explícito da corda | 30 pixels claros conservados e dez interrupções preenchidas; exterior e proteções preservados |
| Cor omitida, cor fora da paleta ou proteção invadida | Protótipo recusa o reparo |

Os resultados estão em `evidence/results.json`. A prancha `figuras/solucao-local.png` ilustra os reparos de equipamento. Não foi medido desempenho de um modelo real, não foi refeita a identidade artística e a suíte integral da Forja não foi reexecutada: o código de produção permaneceu intacto.

## 9. Critério de sucesso para a próxima entrega

Um personagem pronto precisa satisfazer quatro condições: corresponder visualmente ao conceito de autoridade; respeitar tela/grade e papéis de material; conservar as partes fora da mudança autorizada; e ter o estado real de revisão registrado. A prova técnica garante restrições objetivas; a recuperação da expressão é trabalho de desenho.

Para estas três figuras, a execução começa pelo corpo estático. Só depois desse resultado se expandem poses e animações. Em uma animação, a cabeça pode mudar de posição por translação inteira prevista; comparar suas marcas em coordenadas locais evita confundir movimento com redesenho. Expressões alternativas precisam de referências próprias, em vez de permitir que o gerador as invente a cada frame.

## 10. Fontes primárias consultadas

Consulta em 27/10/2026. As recomendações são a aplicação destas fontes ao código e às fixtures do Empire; os resultados numéricos são dos ensaios locais.

- **S01 · PixelLab — Unzoom.** Recuperação de escala e controle de redução de cores. [Fonte](https://www.pixellab.ai/docs/tools/unzoom-pixelart)
- **S02 · Gerstner et al. — Pixelated Image Abstraction with Integrated User Constraints.** Computers & Graphics 37(5), 2013; controles por região, pixel e paleta. Página dos autores: [Fonte](https://cragl.cs.gmu.edu/pixelate/journal.html) · preprint consultado: [Fonte](https://www.nealen.net/papers/pixelated_image_abstraction-journal.pdf)
- **S03 · Saint11 / Pedro Medeiros — Cluster Sketching and Painting.** Agrupamentos, refinamento e função de detalhes isolados. [Fonte](https://saint11.art/pixel_art_articles/article2/)
- **S04 · PixelLab — Inpaint.** Edição por regiões marcadas. [Fonte](https://www.pixellab.ai/docs/tools/inpaint)
- **S05 · PixelLab — Init Images and Inpainting.** Correção iterativa de cabeça e mão. [Fonte](https://www.pixellab.ai/docs/getting-started)
- **S06 · OpenAI — Image Generation.** Máscaras como orientação e limites de precisão. [Fonte](https://developers.openai.com/api/docs/guides/image-generation)
- **S07 · OpenAI — Image Prompting.** Preservação por recomposição quando igualdade de pixels é necessária. [Fonte](https://developers.openai.com/api/docs/guides/image-prompting)
- **S08 · PixelLab — Color Options.** Influência e imposição de paleta. [Fonte](https://www.pixellab.ai/docs/options/color)
- **S09 · Saint11 / Pedro Medeiros — Anti-Alias and Banding.** Ritmo de bordas, suavização e leitura. [Fonte](https://saint11.art/pixel_art_articles/article5/)
- **S10 · PixelLab — OpenAPI v2.** Contrato de conversão e campos de fidelidade; sem ensaio pago nesta pesquisa. [Fonte](https://api.pixellab.ai/v2/openapi.json)
- **Código examinado · Empire, 44e5911.** [Fonte](https://github.com/henriquecoding/empire/tree/44e5911c4374107766f94eb4c28144ad80d5abf0/tools/forja)
