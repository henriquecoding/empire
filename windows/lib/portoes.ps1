# windows/lib/portoes.ps1 - os portoes e os instrumentos, um a um.
#
# Cada um corre o mesmo comando que o alvo do Makefile com o mesmo nome.

function Test-Dados {
    $log = Get-Log 'dados'
    $c = Invoke-Godot -Argumentos @('--headless', '--path', $Raiz, '-s', 'tools/csv_to_tres.gd', '--', '--check') -Log $log
    return (Resolve-Codigo $c $log)
}

function Test-LintSim {
    $log = Get-Log 'lint_sim'
    $c = Invoke-Godot -Argumentos @('--headless', '--path', $Raiz, '-s', 'tools/lint_sim.gd') -Log $log
    return (Resolve-Codigo $c $log)
}

## O `make rng`: um grep, para chumbar mesmo que o ficheiro nao compile.
function Test-Rng {
    $padrao = '\b(randi|randf|randomize|randi_range|randf_range)\s*\('
    $achados = @(Get-ChildItem -Path (Join-Path $Raiz 'src') -Recurse -Filter '*.gd' |
        Where-Object { $_.FullName -notlike '*\src\core\rng_service.gd' } |
        Select-String -Pattern $padrao -CaseSensitive)
    if ($achados.Count -gt 0) {
        foreach ($a in $achados) { Write-Falha ('{0}:{1}: {2}' -f $a.Path.Substring($Raiz.Length + 1), $a.LineNumber, $a.Line.Trim()) }
        return 1
    }
    Write-Host '  G2: sem RNG solto'
    return 0
}

function Test-Suite {
    $log = Get-Log 'gdunit4'
    Write-Nota 'Aparece cada ficheiro de teste quando começa; o detalhe fica no registo.'
    $mostrar = '(Run Test Suite:|\bFAILED\b|^SCRIPT ERROR|Overall Summary|Executed test|Total execution)'
    $c = Invoke-Godot -Log $log -Mostrar $mostrar -Argumentos @(
        '--headless', '--path', $Raiz, '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd', '--ignoreHeadlessMode', '-a', 'tests')
    $html = Select-String -Path $log -Pattern 'Open HTML Report at: (.+)$' | Select-Object -Last 1
    if ($html) { Write-Nota ('Relatório: ' + $html.Matches[0].Groups[1].Value) }
    Write-Nota 'Linhas "ERROR: save: ..." no registo são esperadas: há testes que atacam o save de propósito.'
    # GdUnitTestSessionRunner: 101 e RETURN_WARNING, e nao chumba.
    if ($c -eq 101) { Write-Aviso 'A suite passou com avisos (código 101).'; $c = 0 }
    return (Resolve-Codigo $c $log)
}

function Test-Vistoria([int]$Dias = 8) {
    $log = Get-Log "vistoria_$($Dias)_dias"
    $c = Invoke-Godot -Argumentos @('--headless', '--path', $Raiz, 'scenes/tests/vistoria.tscn', '--', '--dias', "$Dias") -Log $log
    return (Resolve-Codigo $c $log)
}

function Test-Noite {
    $log = Get-Log 'night_test'
    $c = Invoke-Godot -Argumentos @('--headless', '--path', $Raiz, 'scenes/tests/night_test.tscn') -Log $log
    return (Resolve-Codigo $c $log)
}

function Test-DezDias {
    $log = Get-Log 'dez_dias'
    $c = Invoke-Godot -Argumentos @('--headless', '--path', $Raiz, 'scenes/tests/dez_dias.tscn') -Log $log
    return (Resolve-Codigo $c $log)
}

## O que o CI prova com `--quit-after` no binario de Linux: o boot carrega o
## Registry e entrega a game.tscn. Os dois recibos "Empire · semente" dizem-no.
function Test-Arranque {
    $log = Get-Log 'arranque'
    $c = Invoke-Godot -Log $log -Mostrar '^(Empire |SCRIPT ERROR|ERROR)' -Argumentos @(
        '--headless', '--path', $Raiz, '--fixed-fps', '30', '--quit-after', '300', '--', '--novo')
    if ($c -ne 0) { return $c }
    $recibos = @(Select-String -Path $log -Pattern '^Empire \W+ semente' -Encoding UTF8)
    if ($recibos.Count -lt 2) {
        Write-Falha 'O boot não entregou a cena de jogo: faltam os recibos "Empire · semente ...".'
        return 1
    }
    return (Resolve-Codigo 0 $log)
}

## O mesmo ponto do dia que o Makefile conta (NOITE_S), lido do clock.csv.
function Get-SegundosDoRelogio([string]$Ponto) {
    $r = Import-Csv -Path (Join-Path $Raiz 'data\source\clock.csv') -Encoding UTF8 | Select-Object -First 1
    if ($Ponto -eq 'noite') {
        $antes = [double]$r.dawn + [double]$r.morning + [double]$r.noon + [double]$r.afternoon + [double]$r.dusk
        return [int][math]::Floor($antes + [double]$r.night / 2)
    }
    return [int][math]::Floor([double]$r.dawn + [double]$r.morning / 2)
}

## O `make captura`: abre uma janela uns segundos e grava build\capturas\<ponto>.png + .json.
function Invoke-Foto([string]$Ponto) {
    $pasta = Join-Path $Build 'capturas'
    New-Item -ItemType Directory -Force -Path $pasta | Out-Null
    $png = (Join-Path $pasta "$Ponto.png") -replace '\\', '/'
    Remove-Item -Path $png, ($png -replace '\.png$', '.json') -ErrorAction SilentlyContinue
    $log = Get-Log "captura_$Ponto"
    $c = Invoke-Godot -Log $log -Mostrar '^(captura:|SCRIPT ERROR|ERROR)' -Argumentos @(
        '--path', $Raiz, '--resolution', '1280x720', 'tools/captura.tscn', '--',
        '--segundos', '3', '--avancar', "$(Get-SegundosDoRelogio $Ponto)", '--saida', $png, '--novo')
    if ($c -ne 0 -or -not (Test-Path $png)) {
        Write-Falha "A fotografia não saiu (ver $log)"
        return 1
    }
    return (Resolve-Codigo 0 $log)
}

## XIII-01 (§80): a fotografia do meio da noite, e a regra das duas frias contada nela.
function Test-Silhueta {
    $c = Invoke-Foto 'noite'
    if ($c -ne 0) { return $c }
    if (-not (Test-ModuloPython 'PIL')) {
        return 'SALTADO: a fotografia saiu (build\capturas\noite.png), mas contar os píxeis precisa do Pillow'
    }
    $png = (Join-Path $Build 'capturas\noite.png') -replace '\\', '/'
    return (Invoke-Python -Argumentos @('tools/check_silhueta.py', $png) -Log (Get-Log 'silhueta'))
}

function Test-Formato {
    if (-not (Test-ModuloPython 'gdtoolkit')) { return 'SALTADO: falta o gdtoolkit' }
    return (Invoke-Python -Argumentos @('-m', 'gdtoolkit.formatter', '--check', 'src/', 'tests/', 'tools/') -Log (Get-Log 'formato'))
}

function Test-Estilo {
    if (-not (Test-ModuloPython 'gdtoolkit')) { return 'SALTADO: falta o gdtoolkit' }
    return (Invoke-Python -Argumentos @('-m', 'gdtoolkit.linter', 'src/', 'tests/') -Log (Get-Log 'estilo'))
}

function Test-DossieNumeros { return (Invoke-Python -Argumentos @('tools/check_dossie_vs_csv.py', 'docs/dossie.html') -Log (Get-Log 'dossie_numeros')) }
function Test-Conteudo { return (Invoke-Python -Argumentos @('tools/content_report.py', '--check') -Log (Get-Log 'conteudo')) }
function Test-Afirmacoes { return (Invoke-Python -Argumentos @('tools/check_claims.py') -Log (Get-Log 'afirmacoes')) }

## O `make spec` e `split_dossie.py` + `git diff --exit-code`. Aqui compara-se o
## CONTEUDO (o diff normalizado do git, que ignora o CRLF que o Python escreve no
## Windows) e no fim repoe-se o que a ferramenta reescreveu - a pasta estava limpa.
function Test-Spec {
    $antes = @(& git -C $Raiz status --porcelain -- docs/design 2>$null)
    if ($antes.Count -gt 0) { return 'SALTADO: docs/design tem alterações por gravar; não regero por cima' }
    $r = Invoke-Python -Argumentos @('tools/split_dossie.py', 'docs/dossie.html', 'docs/design') -Log (Get-Log 'spec')
    $novos = @(& git -C $Raiz ls-files --others --exclude-standard -- docs/design 2>$null)
    & git -C $Raiz diff --quiet -- docs/design 2>$null
    $diferente = ($LASTEXITCODE -ne 0) -or ($novos.Count -gt 0)
    if ($diferente) {
        Write-Falha 'docs/design não bate com o dossiê:'
        & git -C $Raiz diff --stat -- docs/design 2>$null | Select-Object -Last 6 | ForEach-Object { Write-Host "    $_" }
        foreach ($n in $novos) { Write-Host "    novo: $n" }
    }
    & git -C $Raiz checkout -- docs/design 2>$null
    foreach ($n in $novos) { Remove-Item -Path (Join-Path $Raiz $n) -ErrorAction SilentlyContinue }
    if ("$r" -ne '0') { return $r }
    if ($diferente) { return 1 }
    Write-Host '  docs/design gerado do dossiê: igual ao commit'
    return 0
}

## A camada de uso do dossie (job "dossie" do CI). Os dois portoes precisam do
## Playwright e do Chromium, que ficam por instalar ate alguem decidir que sim.
function Test-CamadaDossie {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { return 'SALTADO: falta o Node' }
    $ferramentas = Join-Path $Raiz 'ferramentas'
    $c = Invoke-Nativo -Exe 'node' -Pasta $ferramentas -Log (Get-Log 'dossie_extrair') -Argumentos @('extrair-dados.mjs', '..', 'saida/dados.json')
    if ($c -ne 0) { return $c }
    $c = Invoke-Nativo -Exe 'node' -Pasta $ferramentas -Log (Get-Log 'dossie_construir') -Argumentos @(
        'construir.mjs', '../docs/dossie.html', 'saida/dados.json', 'saida/dossie-empire.html')
    if ($c -ne 0) { return $c }
    if (-not (Test-Path (Join-Path $ferramentas 'node_modules\playwright'))) {
        return 'SALTADO: o dossiê construiu; os dois portões precisam do Playwright (ver windows\LEIA-ME.md)'
    }
    foreach ($portao in @('verificar-dossie.mjs', 'verificar-novo.mjs')) {
        $c = Invoke-Nativo -Exe 'node' -Pasta $ferramentas -Log (Get-Log "dossie_$portao") -Argumentos @($portao, 'saida/dossie-empire.html')
        if ($c -ne 0) { return $c }
    }
    return 0
}
