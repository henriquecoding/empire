# PixelLab — engenharia reversa: método, contrato, forense e conferência (26/10/2026)

Pedido do dono, a 26/10: *«Quero que se aprofunde intensamente pela web sobre como fazer engenharia
reversa e refine tudo o que já foi feito para a engenharia reversa de https://www.pixellab.ai — um
trabalho completo»*, e depois: *«Hoje também enviei mais uma que está no último deploy da Vercel,
verifica ela também»*. Tarefa: [ART-PIXELLAB-2026-10-26](../../../backlog/ART-PIXELLAB-2026-10-26.md).
Continua a pesquisa de [23/10](../2026-10-23-pixellab/README.md) e confere o envio de
[25–26/10](DOSSIE.md#envio).

| Ficheiro | O que é |
| --- | --- |
| [METODOLOGIA.md](METODOLOGIA.md) | Como se faz engenharia reversa de um serviço de IA: definições, lei (UE, Portugal, Suécia, EUA), os termos do PixelLab, a escada de evidência, o catálogo de técnicas por camada e o que se fez com cada uma |
| [DOSSIE.md](DOSSIE.md) | O que se sabe hoje, com o nível de cada afirmação: contrato, pilha, infraestrutura, SDKs, matriz de hipóteses H01–H15, forense, correções na Forja, conferência do envio de hoje e errata |
| [PROTOCOLO-SONDAGEM.md](PROTOCOLO-SONDAGEM.md) e [sondas.json](sondas.json) | As oito sondas pagas que faltam, com regra de decisão escrita antes de gastar |
| [coleta.py](coleta.py) → [proveniencia.json](proveniencia.json) | 86 respostas públicas: estado, bytes, hash dos bytes e hash do texto normalizado, e a deriva desde 23/10 |
| [contrato.py](contrato.py) → [contrato-2026-10-26.json](contrato-2026-10-26.json) | A impressão digital da especificação OpenAPI, os sinais da pilha e a conformidade da Forja; com `--previous`, a diferença entre datas |
| [conformidade-forja-antes.json](conformidade-forja-antes.json) | As 10 divergências da Forja contra a especificação de hoje, antes do reparo |
| [inferencia_pro.py](inferencia_pro.py) → [inferencia-pro.json](inferencia-pro.json) | A tela interna das ferramentas Pro inferida de preços, contagens e tetos, e o teste contra as tabelas do Gemini |
| [forense.py](forense.py) → [forense-imagens.json](forense-imagens.json) | Escala, grade, cores, alfa e metadados das 60 imagens da documentação (não guardadas aqui) |
| [conferir_envio.py](conferir_envio.py) → [conferencia-forja-04.json](conferencia-forja-04.json) | O pacote de 25/10, os 200 vídeos e as alegações sobre a API, conferidos |
| [verificar.py](verificar.py) → [verificacao.json](verificacao.json) | O verificador do pacote, sem rede |

## Em resumo

- **Método.** Engenharia reversa de um serviço na nuvem recupera o funcional e parte do desenho; os pesos
  e os dados não, e tentá-lo (extração, destilação) violaria os termos. O que se fez: documentação,
  contrato, pilha e infraestrutura por fontes passivas, forense de imagens públicas e inferência por
  invariantes numéricos — sem chave, sem pagar, sem rotas privadas.
- **Achados novos.** A especificação mudou em três dias (o mesmo número de operações, 113 operações,
  outro hash); os termos obrigam à licença Open RAIL-M do Stable Diffusion; a API é Python/FastAPI em
  AWS `eu-west-1`; as ferramentas Pro desenham numa tela de ~1024 px a escala inteira e fatiam, com tetos
  que coincidem com metade da tabela 1K da família Gemini 3.x (indício, não prova); o SDK Python publicado
  só fala com a API v1.
- **Forja reparada.** 10 divergências do adaptador PixelLab corrigidas (63 verificações sem
  divergências); a força 0 da imagem inicial passa a ser recusada antes da rede, porque a API vai de 1 a
  999; a grade deixa de destruir sprites nativos e ampliações exatas (errava 7 de 16 saídas da
  documentação, agora 0 de 16; até 27/10 contava-se 8, ver a errata do dossiê).
- **Envio de hoje conferido.** Pacote 12/12, 200/200 vídeos, alegações verdadeiras, testes e CI verdes.

Nada disto aprova arte, gera imagens, escreve em `art/` ou acrescenta dependências.

## Repetir

Na raiz do repositório; os corpos descarregados ficam numa pasta fora dele.

```bash
R=docs/art/research/2026-10-26-pixellab-engenharia-reversa
W=$(mktemp -d)                                               # fora do repositório
python3 -I $R/verificar.py                                   # sem rede: o pacote é coerente
python3 -I $R/coleta.py --out $W/corpo --output $W/proveniencia.json
python3 -I $R/contrato.py --input $W/corpo/api.pixellab.ai_v2_openapi.json \
    --previous $R/contrato-2026-10-26.json --output $W/contrato.json
python3 -I $R/inferencia_pro.py --corpus $W/corpo --output $W/inferencia-pro.json
python3 -m unittest tools.forja.tests.test_gridcheck tools.forja.tests.test_backends tools.forja.tests.test_request
```

O `contrato.py` diz, em `diff`, que operações entraram, saíram ou mudaram e, em `forja_conformance`, o que
a Forja aceitaria e a API recusaria. A `forense.py` e a `conferir_envio.py` precisam das imagens e do ramo
do PR #123, respetivamente (ver o cabeçalho de cada uma).
