# windows/lib/ferramentas.ps1 - encontrar o Godot e o Python, e o import.

function Get-VersaoFixada { return (Get-Content (Join-Path $Raiz '.godot-version') -Raw).Trim() }

function Get-VersaoNoNome([string]$Nome) {
    if ($Nome -match 'Godot_v(\d+(?:\.\d+)+)') { return [version]$Matches[1] }
    return [version]'0.0'
}

## GODOT, depois a versao fixada em C:\Tools\Godot, depois a mais nova que la
## estiver, depois `godot` no PATH. Devolve o _console.exe, que e o unico que
## escreve na consola, e o .exe de janela, para o editor.
function Find-Godot {
    $candidatos = New-Object System.Collections.Generic.List[string]
    if ($env:GODOT) { $candidatos.Add($env:GODOT) }
    $fixada = Get-VersaoFixada
    foreach ($pasta in @($PastaGodot, (Join-Path $env:USERPROFILE 'Tools\Godot'))) {
        if (-not (Test-Path $pasta)) { continue }
        $candidatos.Add((Join-Path $pasta "Godot_v$($fixada)_win64_console.exe"))
        $achados = @(Get-ChildItem -Path $pasta -Filter 'Godot_v*_win64_console.exe' -ErrorAction SilentlyContinue)
        foreach ($f in ($achados | Sort-Object { Get-VersaoNoNome $_.Name } -Descending)) { $candidatos.Add($f.FullName) }
    }
    $noPath = Get-Command godot -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($noPath) { $candidatos.Add($noPath.Source) }
    foreach ($c in $candidatos) {
        if (-not $c -or -not (Test-Path $c)) { continue }
        $consola = $c
        if ($c -notmatch '_console\.exe$') {
            $irmao = $c -replace '\.exe$', '_console.exe'
            if (Test-Path $irmao) { $consola = $irmao }
        }
        $janela = $consola -replace '_console\.exe$', '.exe'
        if (-not (Test-Path $janela)) { $janela = $consola }
        return [pscustomobject]@{ Consola = $consola; Janela = $janela }
    }
    return $null
}

function Initialize-Godot {
    if ($script:Godot) { return $true }
    $achado = Find-Godot
    if (-not $achado) {
        Write-Falha 'Não encontrei o Godot.'
        Write-Nota "Extrai o ZIP oficial do Godot para Windows para $PastaGodot,"
        Write-Nota 'ou define a variável de ambiente GODOT com o caminho do executável.'
        return $false
    }
    $script:Godot = $achado
    $versao = & $achado.Consola --version 2>$null | Select-Object -Last 1
    $script:VersaoGodot = "$versao".Trim()
    return $true
}

function Test-VersaoFixada {
    $fixada = (Get-VersaoFixada) -replace '-', '.'
    return $script:VersaoGodot.StartsWith("$fixada.")
}

function Show-AvisoDeVersao([switch]$Editor) {
    if (Test-VersaoFixada) { return }
    $curta = ($script:VersaoGodot -split '\.official')[0]
    Write-Aviso "Godot $curta; o projeto está fixado em $(Get-VersaoFixada) (.godot-version)."
    if ($Editor) {
        Write-Nota 'Uma versão mais nova serve para jogar e testar, mas o EDITOR pode reescrever ficheiros do'
        Write-Nota 'projeto (ex.: config/features no project.godot). Não faças commit disso: o CI corre na'
        Write-Nota 'versão fixada. A opção "Estado do ambiente" mostra o que ficou alterado.'
    }
}

function Invoke-Godot {
    param([string[]]$Argumentos, [string]$Log, [string]$Mostrar = '')
    if (-not (Initialize-Godot)) { return 127 }
    return (Invoke-Nativo -Exe $script:Godot.Consola -Argumentos $Argumentos -Log $Log -Mostrar $Mostrar)
}

## O `make importar`, mas so quando e preciso: primeira vez, ou mudou o commit ou o Godot.
function Confirm-Importado([switch]$Forcar) {
    if (-not (Initialize-Godot)) { return 127 }
    $marca = Join-Path $Build '.importado'
    $cabeca = & git -C $Raiz rev-parse HEAD 2>$null | Select-Object -First 1
    $esperado = "$cabeca $($script:VersaoGodot)"
    $i18n = Join-Path $Raiz 'data\i18n'
    $traducoes = @(Get-ChildItem -Path $i18n -Filter '*.translation' -ErrorAction SilentlyContinue).Count
    $pronto = (Test-Path (Join-Path $Raiz '.godot\imported')) -and ($traducoes -ge 2) -and (Test-Path $marca)
    if ($pronto -and -not $Forcar -and ((Get-Content $marca -Raw).Trim() -eq $esperado)) { return 0 }
    Write-Nota 'A importar os recursos (primeira vez, ou mudou o commit ou o Godot)...'
    $log = Get-Log 'importar'
    # Como no `make importar`, o codigo de saida nao conta: num checkout frio o motor
    # queixa-se dos .translation antes de ser ele proprio a gera-los.
    $null = Invoke-Godot -Argumentos @('--headless', '--import', '--path', $Raiz) -Log $log -Mostrar '^SCRIPT ERROR'
    $traducoes = @(Get-ChildItem -Path $i18n -Filter '*.translation' -ErrorAction SilentlyContinue).Count
    if ($traducoes -lt 2) {
        Write-Falha "O import não gerou os .translation (ver $log)"
        return 1
    }
    New-Item -ItemType Directory -Force -Path $Build | Out-Null
    Set-Content -Path $marca -Value $esperado -Encoding ASCII
    return 0
}

## O interpretador verdadeiro e nao o py.exe: parar o servidor Web tem de parar o Python.
function Initialize-Python {
    if ($script:Python) { return $true }
    $py = Get-Command py.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($py) {
        $exe = & $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null | Select-Object -First 1
        if ($exe -and (Test-Path "$exe".Trim())) { $script:Python = "$exe".Trim(); return $true }
    }
    $python = Get-Command python.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notlike '*WindowsApps*' } | Select-Object -First 1
    if ($python) { $script:Python = $python.Source; return $true }
    return $false
}

function Invoke-Python([string[]]$Argumentos, [string]$Log) {
    if (-not (Initialize-Python)) { return 'SALTADO: não encontrei o Python' }
    return (Invoke-Nativo -Exe $script:Python -Argumentos $Argumentos -Log $Log)
}

function Test-ModuloPython([string]$Modulo) {
    if (-not (Initialize-Python)) { return $false }
    & $script:Python -c "import $Modulo" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}
