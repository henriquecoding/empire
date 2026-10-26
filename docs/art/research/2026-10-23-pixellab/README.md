# PixelLab — pesquisa e projeto de uma ferramenta independente

Pesquisa de 23/10/2026 para Henrique Passos. O objetivo é entender capacidades
públicas do PixelLab e especificar como construir um sistema de produção de
pixel art útil ao Empire, com foco em personagens de estudo de 64×64 e 80×80.

**Atualização de 26/10/2026:** a especificação pública mudou de hash, os termos
trazem uma cláusula Open RAIL-M que esta pesquisa não registou e alguns limites
eram também por eixo. O método, os achados novos, a errata e a conformidade da
Forja estão em [2026-10-26-pixellab-engenharia-reversa](../2026-10-26-pixellab-engenharia-reversa/README.md).
Os ficheiros desta pasta ficam como estavam a 23/10.

## Começar por aqui

1. [Auditoria da Forja do Claude](AUDITORIA-FORJA-CLAUDE.md): falhas reproduzidas,
   qualidades, GitHub/Vercel, prioridades e critérios de correção.
2. [Relatório mestre](RELATORIO-MESTRE.md): evidências, arquitetura, dados,
   treino, identidade, animação, cenários, avaliação, exportação e custos.
3. [Prompt para o Claude](PROMPT-PARA-CLAUDE.md): instruções de continuidade
   para transformar o projeto em uma implementação verificável.
4. [Fontes e registro de evidências](FONTES.md): inventário de leitura,
   lacunas e procedência.
5. [Plano de benchmark](benchmark-plan.json): casos, configurações e contagens
   propostas; os resultados continuam nulos porque não houve geração.
6. [Contrato de intercâmbio](asset-contract.schema.json) e
   [exemplo sintético](examples/asset-fixture.json): proposta independente,
   sem substituir o manifesto atual do jogo.

## O que está pronto

O relatório e seus materiais de implementação estão concluídos. Ele separa
documentação pública, inferência e projeto próprio. Não afirma ter recuperado
pesos, dataset ou código privado do PixelLab, nem ter treinado ou medido um
gerador nesta sessão. A qualidade dos futuros modelos depende dos experimentos
descritos no relatório.

A continuidade inclui a auditoria do PR #117 da Forja, já na `main`.
São nove sondas locais, sem rede nem geração, com
[observações registradas](forja-audit-observations.json) e
[evidências de verificação](forja-audit-evidence.json). O relatório orienta
correções na implementação existente; os módulos de produção foram preservados.

Os arquivos HTML e textos integrais de terceiros não são redistribuídos.
As conclusões e instruções originais estão no relatório; URLs e hashes das
respostas consultadas estão em [proveniencia.json](proveniencia.json).

## Repetir as verificações

Na raiz do repositório:

```bash
python3 docs/art/research/2026-10-23-pixellab/validate_research.py
python3 docs/art/research/2026-10-23-pixellab/reproduce_forja_findings.py
```

O primeiro verificador checa integridade documental, JSON, referências, exemplos e
aritmética do plano. Não valida qualidade de imagens nem execução de modelos.
Quando `jsonschema` está disponível, também valida Draft 2020-12 e rejeição de
casos inválidos. Essa checagem foi executada com a versão 4.23.0 num ambiente
temporário, sem acrescentar dependência ao projeto. Na ausência da biblioteca,
o resultado informa que a validação formal não foi executada.

O segundo script requer o Pillow já usado pela Forja. Ele relata o comportamento
do checkout atual em fixtures sintéticas. Após correções, a saída deve mudar;
não é um teste que exija conservar bugs.

Para inspecionar o contrato público atual, sem token e sem criar geração:

```bash
python3 docs/art/research/2026-10-23-pixellab/inspect_public_contract.py
```

Ou usar uma cópia local autorizada da especificação:

```bash
python3 docs/art/research/2026-10-23-pixellab/inspect_public_contract.py --input /caminho/openapi.json
```

O script só faz GET à especificação pública quando não recebe `--input`.
Uma mudança de hash exige revisar o adaptador antes de reutilizar limites.
Condições descritas apenas em prosa podem não aparecer como restrição JSON.

## Relação com o projeto

O ponto de entrada de produção continua sendo
[CHARACTER_PRODUCTION_GUIDE.md](../../CHARACTER_PRODUCTION_GUIDE.md).
Esta pesquisa não muda aprovação artística, regras de gameplay, dimensões
canônicas, runtime ou dependências. Os contratos propostos só entram no produto
com implementação, testes e revisão correspondentes.

Tarefa: [ART-PIXELLAB-2026-10-23](../../../backlog/ART-PIXELLAB-2026-10-23.md).
Evidência dos checks locais: [verificacao.json](verificacao.json).
