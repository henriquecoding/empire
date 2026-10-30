# Regras do dono — consultar antes de produzir e antes de entregar

Estas regras de Henrique são obrigatórias para qualquer agente e gerador. A fonte executável é
[`owner_rules.json`](../../tools/forja/owner_rules.json); `python3 -m tools.forja regras` mostra as regras,
as falas que lhes deram origem e a leitura obrigatória. O conceito escolhido mais recente prevalece
sobre propostas históricas e sobre avaliações positivas de um assistente.

## Antes de produzir

1. Ler este documento, AGENTS.md, os guias de produção, pixel art, Aseprite e Forja.
2. Consultar `forja elenco`, a autoridade, a função, a escala, as invariantes e as rejeições.
3. Compilar o pedido por `forja prompt/plan/elenco --character`. Conservar o texto, anexos e
   `expect`, incluindo a revisão das regras e o hash do recorte de autoridade.
4. Desenhar o orçamento nativo: silhueta, cabeça/expressão, mãos, objeto, contactos, apoio e oclusão.
   A tropa e o escudeiro atuais usam 64×64; os imperadores grandes do catálogo, Rei e Arqueiro Real
   usam 80×80. O arqueiro de tropa não é o Arqueiro Real. Outros corpos seguem o seu contrato explícito.
5. Quando o conceito já é pixel art, recuperar primeiro a grade real. Quando exige redesenho,
   redesenhar na grade final. Não reduzir uma ilustração detalhada como substituto de autoria nativa.
   `--reduce` continua disponível para diagnóstico, mas essa cadeia não passa a entrega.
6. Nunca usar um candidato rejeitado para substituir o conceito, mesmo como guia de densidade.
   A lista de hashes nativos rejeitados não rejeita os conceitos originais que continuam aceites.

## Rever a arte, não apenas os ficheiros

| Aspeto | Regra obrigatória |
| --- | --- |
| Identidade | Conceito e sprite muito próximos; conservar silhueta, corpo, gesto, roupa, materiais e personalidade. Não redesenhar sem instrução. |
| Grade útil | Anotar tela, caixa ocupada e espaço para cabeça, mãos e equipamento. Dimensões do PNG não provam densidade. Não esticar a figura nem impor percentagem arbitrária de preenchimento. |
| Contorno | Intenção de 1 px, escadas e junções deliberadas, sem pixels duplos acidentais. Dilatação automática não conclui o desenho. Cantos espessos precisam de revisão contextual; não apagar olhos ou brilhos por serem pequenos. |
| Mãos e pega | Dedos, punho, anatomia, apoio, peso e oclusão corretos. Contacto entre pixels não prova que a mão segura o objeto. Rever mão e objeto juntos. |
| Expressão | Conservar olhar, pálpebras, sobrancelhas, nariz na família da pele, boca, assimetria, dentes e pelos. Contar dentes ou preservar pinos não prova atuação facial. Barba e bigode persistem no dano. |
| Poção | Bojo redondo, gargalo, aro, rolha, volume e brilho como no conceito. Igualdade de envelope não prova forma. Os dois alquimistas usam o mesmo tamanho absoluto. Não substituir por molde improvisado separado da mão. |
| Armas | Lâmina/haste contínua, partes e contactos corretos, sem duplicações, torções ou partes ausentes. Corrigir defeitos conhecidos da referência. |
| Cores | Planos de luz e agrupamentos coerentes por material. Sem teto arbitrário de 24 cores; não apagar pupilas, dentes ou brilhos. Proposta de rampa não equivale a paleta de runtime aprovada. |
| Elenco | Respeitar aprovações e rejeições mais recentes. Horta humana; nabo colhido, nunca corpo-planta. Não substituir escudeiro real já definido. |
| Animação | Poses-chave e intermediários com articulações, apoio e peso. Não simular movimento por rotação de recortes rígidos. Braços/equipamento permanecem; flores crescem uma a uma, organicamente. Respeitar Sombra/bailarina aceites. |
| Mundo | Cenários pela régua dos atores, camadas, continuidade e acessos inferiores funcionais. Animais pequenos menores que os grandes. Preservar leitura sem ruído excessivo. |

## Antes de entregar

Produzir uma prova pequena antes de expandir o lote. Comparar o conceito, a fonte gerada e o sprite
a 1× e numa ampliação inteira, em fundos claro/escuro e lado a lado. O observador preenche a revisão
da imagem exata; quem não viu deixa pendente. Não preencher tudo com pass por ter exportado sem erro.

`forja visual ID.png --fidelity CONTRATO --character ID --template-out revisao.json` inclui a ficha destas
regras. Preencher observador, vistas, caixas e evidência de cada aspeto; guardar como `ID.visual.json`
ao lado de `ID.png` e do JSON do forge. Cada alteração ao PNG ou às regras invalida a revisão antiga.
Conservar a cadeia com `--lineage`: uma reexportação nativa não apaga a redução ou perdas anteriores.

`forja fidelity CONTRATO --character ID --candidate ID.png --forge-json ID.json --visual-review ID.visual.json` e `forja lote` mostram
`production_review` e `ready_for_review`. O portão `forja entrega PASTA` falha se faltar
um personagem ou se qualquer candidato não estiver pronto para revisão. Para um piloto explicitamente
limitado, usar `--character ID`; isto não declara completo o elenco. A aprovação final do mestre
continua separada e pertence ao dono: `ready_for_review` não é `release_ready`.

Fidelidade pendente, defeito certo, revisão desatualizada, redução com perda e ausência de consulta
não se tornam entrega por passar tamanho, alfa, exportação Aseprite ou testes. Um ficheiro de
diagnóstico pode ser guardado; não deve ser apresentado como resposta concluída ao pedido de sprites.

## Caso de 30/10/2026

O lote foi rejeitado pelo dono por mãos, contornos duplicados, expressões, forma/pega da poção e
resolução aparente. O processo usou fontes de 1254×1254, redução deliberada e guias nativos anteriores
defeituosos; um molde novo da poção e dentes contados não resolveram a fidelidade. O lote da Forja
tinha as 15 entradas bloqueadas com a paleta do jogo e a fidelidade continuava pendente.

O teste controlado dos 15 mesmos inputs e parâmetros, antes das correções locais, produziu os
mesmos pixels em d0afd25 e a68521e nas duas etapas. Isto não é prova de qualidade: identifica que
essa regressão da entrega veio do processo aplicado, sem evidenciar regressão do conversor nesse teste.
Nenhum agente pode voltar a atribuir bom acabamento ao facto de usar a Forja mais recente.
