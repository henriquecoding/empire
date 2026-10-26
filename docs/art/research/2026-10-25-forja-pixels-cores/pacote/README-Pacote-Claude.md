# Forja — pacote de pesquisa para o Claude

Pesquisa de 25 de outubro de 2026 sobre pixels desconexos, clusters, paleta e continuidade temporal no Empire.

## Ordem de leitura

1. `Relatorio-Forja-Pixels-Cores-Claude-2026-10-25.md`: diagnóstico, evidências e proposta em 24 seções. A seção 22 contém a instrução para implementação.
2. `Dossie-PixelLab-200-Videos-2026-10-25.md`: cobertura individual dos 200 itens e 40 fichamentos, dos quais cinco são recortes temáticos de lives.
3. `catalogo/cobertura-videos.csv` ou `.json`: índice pesquisável, idiomas, datas disponíveis, marcas de legenda, situação e hashes.
4. `evidencias/resultados.json`: resultados das provas sintéticas e medições dos três assets anteriores.

## Leitura correta da cobertura

O inventário público foi percorrido até o fim. Foram recuperados 180 arquivos de legenda automática, dos quais 20 são muito breves; 20 itens permaneceram sem transcrição retornada após nova tentativa. Recuperar legenda não significa revisar todo o áudio ou assistir integralmente ao vídeo. Os arquivos brutos das falas protegidas de terceiros não fazem parte desta entrega; há sínteses originais com localização nas fontes.

## Reproduzir as provas

O snapshot auditado é `4471cde384c94e8833e4e61347551ac8c69320b0` do repositório `henriquecoding/empire`. Os hashes das fontes estão em `evidencias/fontes-codigo.json` e nos resultados. O script usa os módulos reais de `tools/forja`, requer Pillow e grava evidências num diretório separado; não chama APIs de geração.

```bash
python provas-pixels-cores.py \
  --forja-dir /caminho/empire/tools/forja \
  --out /caminho/evidencias-pixels-cores
```

O argumento opcional `--assets` recebe a pasta com `rei/rei.png`, `arqueiro/arqueiro.png` e `escudeiro/escudeiro.png` do pacote anterior. Esses assets não são necessários para repetir as provas sintéticas. Compare o código atual com o snapshot antes de interpretar diferenças.

## Prioridades

- Distinguir fragmentação cromática de isolamento de alpha.
- Preservar detalhes autorizados em todas as etapas de acabamento.
- Resolver a precedência entre paleta fornecida e orçamento de cores.
- Restringir correção temporal a regiões e mudanças cuja intenção seja conhecida.
- Revisar o resultado a 1×, em ampliação inteira e dentro da composição do jogo.

Os testes reproduzem lacunas técnicas; não demonstram a causa de todo defeito visual nem aprovação artística. Não houve alteração de produção, commit, deploy, treinamento ou nova geração paga de assets nesta pesquisa.

`MANIFESTO-SHA256.json` permite conferir a integridade dos arquivos do pacote. `fichamentos-video.json` contém apenas as sínteses originais.
