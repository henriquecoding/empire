# ADR 0013 — A massa da noite escreve-se de dia, com os teus mortos

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §05, §51, §74

## Contexto
A Podridão da v5.2 é meteorologia com orçamento: `M = 60 + 26 × dia + 40 × fortalezas`. Durante os 85 s da Manhã e
os 85 s da Tarde não há nada que o jogador possa fazer em relação à noite de hoje — ela já está decidida pelo
calendário. A curva de dificuldade é uma reta escrita à mão.

## Decisão
A massa passa a ter termos que o jogador escreve: uma tropa que morre fora das muralhas e não é recolhida antes da
alvorada cria raiz e vira Amargueiro, e cada Amargueiro de pé alimenta a noite seguinte.

    M = 40 + 18 × dia + 30 × fortalezas
      + 22 × amargueiros + 45 × amargueiros_nomeados
      + 8  × min(recusas_nos_ultimos_5_dias, 5)

A base e o termo do dia descem de propósito: o que a noite tem de duro deixa de vir do calendário. Um Amargueiro
tem três destinos, todos com o Verbo 1: cortar (6 moedas, 12 s, só depois de uma noite de pé), consagrar (1 Semente
Real, vira Marco, protege 120 px) ou deixar. A Podridão passa a trazer uma candeia: raio `150 + 4 × dia` px com teto
em 260, âmbar, a única fonte quente do campo que não é do jogador.

## Alternativas consideradas
Manter a fórmula antiga e acrescentar só os Amargueiros: ao dia 20 dava 580 + 176 num campo médio, e a Parte XIII
passava a ser um imposto em cima da curva antiga em vez de a substituir. Rejeitado — a tabela da §74 mostra que com
os coeficientes novos um jogador cuidadoso tem −31% e um descuidado +11%, que é o intervalo que se queria.
Dar preço ao Lenho Amargo: um vagabundo custa 1 moeda; três Lenhos a 40 moedas transformavam o sistema numa máquina
de matar os próprios. Rejeitado, e o teste D-02 impede que volte.

## Consequências
`rot.csv` ganha os cinco termos novos e `amargueiros.csv` os três destinos. O Lenho Amargo não se vende, não se
troca e não tem preço — serve para dispensar o `requires_conquest` da muralha de nível 4 por segmento, e o bastião
custa 3 Lenhos além das 65 moedas. O `docs/content/ROT_BY_DAY.md` passa a mostrar o piso da fórmula e a dizer que o
resto se joga. O Zelador (§75) fica fora da conta de invocações: nasce da Dívida, não da massa.
Reverter obriga a refazer a tabela da §74, a §82 (4 h da §80 + 1 h + 13 h) e os testes D-01 a D-03.
