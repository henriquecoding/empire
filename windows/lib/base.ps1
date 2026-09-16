# windows/lib/base.ps1 - escrever, os registos, correr programas, os passos e o resumo.

function Write-Titulo([string]$Texto) {
    Write-Host ''
    Write-Host "== $Texto" -ForegroundColor Cyan
}
function Write-Ok([string]$Texto) { Write-Host "  [ok] $Texto" -ForegroundColor Green }
function Write-Aviso([string]$Texto) { Write-Host "  [!]  $Texto" -ForegroundColor Yellow }
function Write-Falha([string]$Texto) { Write-Host "  [x]  $Texto" -ForegroundColor Red }
function Write-Nota([string]$Texto) { Write-Host "       $Texto" -ForegroundColor DarkGray }

function Write-Linha([string]$Linha) {
    if ($Linha -match '^\s*(SCRIPT ERROR|USER ERROR|ERROR)\b' -or $Linha -match '\bFAILED\b') {
        Write-Host $Linha -ForegroundColor Red
    } elseif ($Linha -match '^\s*(USER WARNING|WARNING)\b') {
        Write-Host $Linha -ForegroundColor Yellow
    } else {
        Write-Host $Linha
    }
}

## Cada accao tem a sua pasta de registos, build\logs\<data>_<accao>\, criada so
## quando alguem escreve la dentro.
function Start-Accao([string]$Nome) {
    $carimbo = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $script:PastaLogs = Join-Path $Build "logs\$($carimbo)_$Nome"
}
function Get-Log([string]$Nome) { return (Join-Path $script:PastaLogs "$Nome.log") }

## O import do Godot varre o projeto inteiro. Sem isto, as fotografias de
## build\capturas e o logo.png de cada relatorio do gdUnit4 passavam a recursos do
## projeto, e as fotografias entravam no .pck de um export local (o exclude_filter
## do export_presets.cfg tira reports/ mas nao build/). As duas pastas estao no .gitignore.
function Confirm-PastasIgnoradas {
    foreach ($pasta in @($Build, (Join-Path $Raiz 'reports'))) {
        $marca = Join-Path $pasta '.gdignore'
        if (Test-Path $marca) { continue }
        New-Item -ItemType Directory -Force -Path $pasta | Out-Null
        New-Item -ItemType File -Path $marca | Out-Null
    }
}

## Corre um executavel, mostra as linhas (todas, ou so as que casam com -Mostrar),
## grava-as sem cores no registo e devolve o codigo de saida.
function Invoke-Nativo {
    param(
        [string]$Exe,
        [string[]]$Argumentos,
        [string]$Log,
        [string]$Mostrar = '',
        [string]$Pasta = $Raiz
    )
    $escritor = $null
    if ($Log) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Log) | Out-Null
        $escritor = New-Object System.IO.StreamWriter($Log, $false, (New-Object System.Text.UTF8Encoding($false)))
    }
    $codigo = 1
    Push-Location $Pasta
    try {
        & $Exe @Argumentos 2>&1 | ForEach-Object {
            $linha = $Ansi.Replace([string]$_, '')
            if ($escritor) { $escritor.WriteLine($linha) }
            if (-not $Mostrar -or $linha -match $Mostrar) { Write-Linha $linha }
        }
        $codigo = $LASTEXITCODE
    } finally {
        Pop-Location
        if ($escritor) { $escritor.Dispose() }
    }
    return [int]$codigo
}

## Um codigo 0 com SCRIPT ERROR no registo nao e um passo verde.
function Resolve-Codigo([int]$Codigo, [string]$Log) {
    if ($Codigo -ne 0) { return $Codigo }
    if ($Log -and (Test-Path $Log) -and (Select-String -Path $Log -Pattern '^SCRIPT ERROR' -Quiet)) {
        Write-Falha "Houve SCRIPT ERROR (ver $Log)"
        return 1
    }
    return 0
}

## Um bloco devolve 0 (passou), outro numero (falhou) ou 'SALTADO: porque'.
## Os parametros de blocos tem nomes diferentes em cada funcao de proposito: o
## PowerShell resolve variaveis pela pilha de chamadas, e um nome repetido fazia
## um bloco chamar-se a si proprio.
function Invoke-Passo([string]$Nome, [scriptblock]$Accao) {
    Write-Titulo $Nome
    $relogio = [System.Diagnostics.Stopwatch]::StartNew()
    $estado = 'FALHOU'
    $nota = ''
    try {
        $saida = @(& $Accao)
        $r = 0
        if ($saida.Count -gt 0) { $r = $saida[-1] }
        if ($r -is [string] -and $r.StartsWith('SALTADO')) {
            $estado = 'SALTADO'
            $nota = $r.Substring(7).TrimStart(':', ' ')
        } elseif ("$r" -eq '0') {
            $estado = 'OK'
        } else {
            $nota = "código $r"
        }
    } catch {
        $nota = $_.Exception.Message
    }
    $relogio.Stop()
    $segundos = [math]::Round($relogio.Elapsed.TotalSeconds, 1)
    $script:Resultados.Add([pscustomobject]@{ Passo = $Nome; Resultado = $estado; Segundos = $segundos; Nota = $nota })
    switch ($estado) {
        'OK' { Write-Ok "$Nome ($segundos s)" }
        'SALTADO' { Write-Aviso "$Nome - saltado: $nota" }
        default { Write-Falha "$Nome - falhou ($nota)" }
    }
}

function Show-Resultados([string]$Titulo) {
    Write-Titulo $Titulo
    $tabela = $script:Resultados | Format-Table -AutoSize -Wrap | Out-String -Width 170
    Write-Host $tabela
    $cabecalho = "$Titulo - $(Get-Date -Format 'yyyy-MM-dd HH:mm') - Godot $($script:VersaoGodot) - commit " +
        (& git -C $Raiz rev-parse --short HEAD 2>$null | Select-Object -First 1)
    New-Item -ItemType Directory -Force -Path $script:PastaLogs | Out-Null
    Set-Content -Path (Join-Path $script:PastaLogs 'resumo.txt') -Value @($cabecalho, $tabela) -Encoding UTF8
    $falhas = @($script:Resultados | Where-Object { $_.Resultado -eq 'FALHOU' }).Count
    $saltados = @($script:Resultados | Where-Object { $_.Resultado -eq 'SALTADO' }).Count
    if ($falhas -eq 0) { Write-Ok "Nada falhou ($saltados saltado(s)). Registos: $script:PastaLogs" }
    else { Write-Falha "$falhas passo(s) falharam. Registos: $script:PastaLogs" }
    return $falhas
}
