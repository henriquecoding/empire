# Forja: plano de fidelidade e critérios de aceite

Especificação derivada da auditoria de 27/10/2026, revisão 2. **Não implementada em produção.** Referência de código: `henriquecoding/empire`, commit `0fea413d05b35d9311801c16d4dca883feceed52`.

O problema concreto é a entrega de candidatos com roupa, atuação e proporções divergentes, apesar de arquivos compatíveis com o runtime. A mudança precisa conservar as telas atuais e acrescentar evidências de identidade e de perda de sinais. Não exige mudar o estilo do jogo ou aumentar a resolução para esconder a falha.

## 1. Autoridade rastreável antes de compilar o pedido

**Pontos de integração:** módulos de referência existentes e `prompts.py`. Reutilizar os registros atuais; evitar criar uma segunda fonte de verdade concorrente.

**Comportamento proposto:** identificar personagem, pose, hash da origem e recorte; declarar operação `recover_grid`, `adapt_concept` ou `edit_approved_master`. Um guia derivado pode indicar layout, mas conserva o vínculo com a origem e seu estado de revisão. Em adaptação, o conceito continua presente na geração.

**Critérios de aceite:**

- Um pedido do arqueiro desta prancha aponta para o recorte da roupa creme, capuz verde e arco baixo. Um arquivo alternativo de túnica verde comprida aparece como conflito de referência, exigindo resolver o alvo antes de gerar.
- Um guia reprovado não substitui o conceito nem vira mestre por ter o tamanho correto.
- O modo fiel não recebe automaticamente “dois tons por material” ou “12–24 cores” quando não há essa regra no contrato ou na direção de arte.
- O pedido gerado registra a origem de cada restrição. Perfil, simplificação e limite de cor não entram por uma preferência implícita do compilador.

**Prova:** comparar o pedido compilado e o manifesto de referências contra a proposta JSON incluída. A ferramenta pode provar quais arquivos anexou; a correção da pose e roupa ainda exige inspeção do recorte.

## 2. Separar grade recuperada de redução deliberada

**Pontos de integração:** `gridcheck.py`, `grid.py`, `pipeline.snap` e relatório.

**Comportamento proposto:** conservar o caminho de ampliação exata e suas provas. Acrescentar `origin` explícito à grade: medida exata, estimada, declarada ou reduzida deliberadamente. Mostrar dimensões de entrada, grade de saída e adequação ao contrato. Uma escala fornecida pelo operador não pode aparecer como evidência independente de autoria nativa.

**Critérios de aceite:**

- Os 12 controles PNG inteiros continuam recuperando exatamente a origem conhecida, incluindo fase deslocada e blur leve das fixtures.
- Uma entrada mista que produz 128×128, diante de um destino 16×16 no ensaio, informa a diferença de orçamento. A ferramenta não rotula automaticamente uma redução posterior como recuperação fiel.
- A estimativa recusada nas três entradas bilineares continua visível. A mensagem orienta o uso de `--scale` quando a origem é conhecida e identifica a redução quando a escolha é uma adaptação.
- JPEG pode ter grade exata e conteúdo cromático inexato; o relatório não funde essas duas afirmações.

**Prova:** executar `testar_grade.py` e comparar tamanho, RGBA, alfa e origem da grade separadamente. O tempo de execução é informativo e não faz parte da igualdade do resultado.

## 3. Medir informação descartada pelo amostrador

**Pontos de integração:** `resample.py`, `pipeline.subgrid` e representação do diagnóstico. Se a mudança ampliar demais um arquivo, separar um módulo de diagnósticos, respeitando o limite de linhas do repositório.

**Comportamento proposto:** manter a escolha de cor e acrescentar observação da célula completa antes do recuo. Registrar área considerada, diversidade/contraste fora do núcleo, cobertura alfa da entrada, motivo do descarte e divergência entre núcleo e célula inteira. Células que viraram transparentes continuam presentes nos dados de perda.

Não trocar silenciosamente o método padrão com base nestes seis exemplos. O recuo atual ajuda a remover bordas suavizadas; diminuir o recuo também apagou uma marca que antes sobrevivia. O diagnóstico e as restrições precisam orientar a decisão.

**Critérios de aceite:**

- O traço de borda de 3 pixels continua detectável no relatório de perda, mesmo que a saída dominante siga uniforme.
- A linha alfa de 4 pixels registra 12 células descartadas com conteúdo declarado importante. Não desaparece da avaliação por ter alfa zero na saída.
- A marca clara central gera evidência na região declarada, sem depender de atingir 5% da imagem.
- O controle de célula inteira permanece preservado e não é rotulado como perda.
- `mode`, `center`, `median` e `mean` não exibem seu 1,0 convencional como uma pureza medida equivalente ao dominante.

**Prova:** os scripts atuais caracterizam o comportamento antigo. Para a implementação, convertê-los em regressões com expectativas explícitas sobre presença de diagnósticos e preservação autorizada. Um comando que executa sem erro não significa que o problema foi corrigido.

## 4. Restrições locais sem sobrescrita silenciosa

**Pontos de integração:** uma camada pequena de restrições ligada à amostragem/composição e verificações após as operações de acabamento. Reutilizar as máscaras e provas de preservação já existentes quando adequado.

**Comportamento proposto:** regiões e pixels declarados importantes recebem regras verificáveis. Cada restrição indica de onde veio, sua função e o que pode mudar. Uma exigência de cor num pixel pode ser aplicada apenas quando a decisão de adaptação já estiver autorizada e não conflitar com outra exigência.

Exemplo mínimo proposto:

```json
{
  "target_pixel": [42, 25],
  "role": "eyelid",
  "required_palette_role": "face_dark",
  "source_annotation": "king-face-review-01",
  "status": "illustrative_only_not_an_annotation_of_the_real_king"
}
```

As coordenadas acima são apenas um exemplo de formato. O JSON principal deixa as coordenadas reais pendentes. Não se deve transformar este exemplo numa edição do rosto.

**Critérios de aceite:**

- Duas restrições com cores diferentes para o mesmo pixel produzem `layout_conflict` com as duas origens; a ordem de processamento não decide silenciosamente qual vence.
- Um sinal protegido continua verificado após paleta, limpeza, contorno, encaixe e composição. Se uma etapa o remove ou desloca sem mapeamento válido, a fidelidade fica bloqueada.
- Restrições que ainda não têm coordenadas ou material resolvidos ficam pendentes.
- A prova do exterior inalterado continua obrigatória ao editar um mestre aprovado. Nenhum candidato rejeitado desta rodada entra nesse modo.

**Prova:** casos de conflito, preservação após acabamento e perda declarada. A aplicação de uma cor prova o cumprimento da restrição; não prova que o olho tenha sido bem desenhado.

## 5. Revisão visual com estados separados

**Pontos de integração:** relatórios, expectativa e encerramento da Forja.

**Comportamento proposto:** apresentar quatro estados: runtime, preservação declarada, identidade/pose e aprovação de mestre. Cada um aponta para sua evidência. Uma revisão artística inclui observações concretas por região, sem uma nota global inventada.

**Critérios de aceite:**

- A roupa verde comprida do arqueiro anterior bloqueia a revisão de identidade para esta prancha, mesmo que dimensões, alfa e paleta passem.
- Rosto, roupa, proporção, mãos e equipamento aparecem lado a lado com a mesma pose de referência, em escala nativa e ampliação inteira.
- Um campo não avaliado permanece pendente. Uma exigência obrigatória reprovada permanece bloqueada. Um agente não preenche a aprovação do autor.
- `approved_master` exige o hash da imagem exata realmente aprovada pelo usuário, conforme as regras já existentes do projeto.

**Prova:** cenários de transição de estados e revisão das evidências exibidas. O acerto semântico não é validado pela mera existência de caixas marcadas por quem gerou o candidato.

## 6. Piloto artístico que pode demonstrar recuperação

Começar pela pose estática superior do rei. Antes de qualquer geração, preencher as regiões críticas e o layout nativo sem congelar a anatomia de um guia rejeitado. Reservar espaço para olho, sobrancelha, nariz, sorriso e bochecha, além de corpo largo e materiais. Manter o conceito original como referência de identidade em cada tentativa.

Guardar o retorno bruto antes de amostrar ou quantizar. Primeiro conferir atuação e proporção. Se a base divergir, corrigir o desenho relevante antes de produzir uma série. Quando a base estiver fiel, usar acabamento local com prova de preservação.

Para comparar conversores, usar a mesma origem, destino e restrições e mudar uma variável por vez. Guardar modelo/versão e parâmetros que o serviço realmente expõe. Os parâmetros PixelLab descritos no relatório são uma proposta de experimento; nenhuma execução paga ocorreu nesta pesquisa. Métodos dos artigos também não foram implementados.

O êxito artístico será uma base nativa legível, próxima da expressão e dos materiais do conceito e revista pelo autor. Uma imagem que acerta a grade mas altera a atuação é uma tentativa reprovada. Animações e demais personagens dependem dessa base.

## 7. Conjunto de avaliação e encerramento honesto

| Conjunto | Serve para verificar | Não demonstra |
|---|---|---|
| 12 variantes de paleta da primeira revisão | Efeito isolado da quantização final | Efeito causal de cada frase do prompt |
| 60 configurações sintéticas do amostrador | Perda de marca por voto, recuo e cobertura | Qualidade de rostos reais |
| 12 passagens sintéticas pelo pipeline | Persistência do mecanismo no fluxo executado | Aprovação nos contratos reais de personagem |
| 21 perturbações sobre PNGs conhecidos | Recuperação de grade, alfa e RGBA | Fidelidade artística das fixtures rejeitadas |
| Pares conceito/candidato futuros, aceitos e rejeitados pelo autor | Leitura de identidade e qualidade no projeto | Uma métrica universal para qualquer estilo |

As novas observações somam 93 configurações/passagens, com reutilização de fixtures. Não são uma amostra estatística independente. SSIM/LPIPS podem auxiliar comparações controladas, mas não recebem limiar de aprovação sem validação em pares do projeto.

Neste estado, a pesquisa e a especificação estão produzidas; o código de produção e a reconstrução dos personagens continuam pendentes. A mudança só deve ser descrita como implementada depois de existir um diff revisável, verificações apropriadas e evidência do comportamento. A recuperação artística só deve ser descrita como concluída depois da revisão da imagem exata.
