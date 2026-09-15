# 85 — Anexo · novo · Os ficheiros de dados

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Tudo o que esta parte decide está em CSV, com as mesmas colunas de disciplina que a §71 impôs ao resto: _phase, _src, _proposed e _notes. O que veio do dossiê está marcado como tal; o que foi proposto aqui está marcado como proposta, uma coluna a uma. Nada foi decidido em silêncio, e o content_report.py continua a poder contar.

| Ficheiro | Linhas | O que guarda | Secção |
| --- | --- | --- | --- |
| data/source/rot.csv | 1 | A Podridão: fórmula da massa termo a termo, velocidade, candeia, raio de luz, limiares da Dívida | §74 · §75 |
| data/source/amargueiros.csv | 3 | Os três destinos, custos, rendimentos e o efeito na massa | §74 |
| data/source/offers.csv | 12 | As doze ofertas: frase, preço, efeito, condição, dívida | §75 |
| data/source/titles.csv | 9 | Os nove feitos, os títulos e o que cada um dá | §76 |
| data/source/chapters.csv | 10 | Os dez capítulos: lei, habitante, canção, diário, bioma | §77 |
| data/source/journals.csv | 12 | Os doze diários: ato, origem, objeto físico, o que revela | §79 |
| data/source/peoples.csv | 6 | Alterado: +song_texture, +colheita_song, +landmark_roots | §78 · §81 |
| data/source/creatures.csv | +1 | Alterado: +tender — o Zelador, que não ataca | §75 |
| data/source/clock.csv | 1 | Alterado: +night_tint_hsv, o castanho da §80 | §80 |
| src/sim/data/*.gd | 5 | RotData alargado, AmargueiroData, OfferData, TitleData, ChapterData | todas |


> **Onde caem no repositório**
>


O conversor tools/csv_to_tres.gd gera os 154 recursos a partir das 17 tabelas registadas em data/source/_tables.csv. Os scripts em tools/recovered_generators/ são geradores históricos de CSV, não de .tres; não devem repor os dados durante o balanceamento. O architecture_test.gd continua a valer sem alterações — nenhum destes recursos importa nada de fora de src/sim/.
