# windows/lib/builds.ps1 - exportar aqui, trazer as builds do CI, e joga-las.

function Get-PastaTemplates {
    if (-not (Initialize-Godot)) { return $null }
    if ($script:VersaoGodot -match '^(\d+(?:\.\d+)+\.[a-z]+[0-9]*)\.') {
        return (Join-Path $env:APPDATA ('Godot\export_templates\' + $Matches[1]))
    }
    return $null
}

function Test-ComTamanho([string[]]$Ficheiros) {
    foreach ($f in $Ficheiros) { if (-not (Test-Path $f) -or (Get-Item $f).Length -eq 0) { return $false } }
    return $true
}

## O `make exportar-windows exportar-web`. O de Linux fica de fora: nao arranca aqui,
## e o que ele prova - que o binario arranca - so vale na plataforma que o corre.
function Invoke-Exportar {
    $templates = Get-PastaTemplates
    $faltam = @(@('windows_debug_x86_64.exe', 'web_nothreads_release.zip') |
        Where-Object { -not $templates -or -not (Test-Path (Join-Path $templates $_)) })
    if ($faltam.Count -gt 0) {
        return "SALTADO: faltam os templates de export em $templates (no editor: Editor > Gerenciar Modelos de Exportação). Alternativa: as builds do CI"
    }
    $falhou = $false
    $win = Join-Path $Build 'windows'
    New-Item -ItemType Directory -Force -Path $win | Out-Null
    $c = Invoke-Godot -Log (Get-Log 'exportar_windows') -Mostrar '^(SCRIPT ERROR|ERROR)' -Argumentos @(
        '--headless', '--path', $Raiz, '--export-debug', 'Windows Desktop', ((Join-Path $win 'empire.exe') -replace '\\', '/'))
    if ($c -ne 0 -or -not (Test-ComTamanho @((Join-Path $win 'empire.exe'), (Join-Path $win 'empire.pck')))) {
        Write-Falha 'O export de Windows não saiu inteiro.'
        $falhou = $true
    } else { Write-Ok 'build\windows\empire.exe e empire.pck' }
    $web = Join-Path $Build 'web'
    New-Item -ItemType Directory -Force -Path $web | Out-Null
    $c = Invoke-Godot -Log (Get-Log 'exportar_web') -Mostrar '^(SCRIPT ERROR|ERROR)' -Argumentos @(
        '--headless', '--path', $Raiz, '--export-release', 'Web', ((Join-Path $web 'index.html') -replace '\\', '/'))
    if ($c -ne 0 -or -not (Test-ComTamanho @((Join-Path $web 'index.wasm'), (Join-Path $web 'index.pck')))) {
        Write-Falha 'O export Web não saiu inteiro.'
        $falhou = $true
    } else { Write-Ok 'build\web\index.html, .wasm e .pck' }
    if ($falhou) { return 1 }
    return 0
}

function Get-RepositorioGitHub {
    $url = & git -C $Raiz remote get-url origin 2>$null | Select-Object -First 1
    if ("$url" -match 'github\.com[:/](.+?)(\.git)?$') { return $Matches[1] }
    return $null
}

## Os artifacts empire-windows-debug e empire-web da corrida verde do CI deste commit
## (ou, nao havendo, da mais recente do ramo). Expiram: ver retention-days no ci.yml.
function Save-BuildsDoCI {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Falha 'Falta o GitHub CLI (gh).'; return 1 }
    $repo = Get-RepositorioGitHub
    if (-not $repo) { Write-Falha 'O remote origin não é um repositório do GitHub.'; return 1 }
    $ramo = & git -C $Raiz branch --show-current 2>$null | Select-Object -First 1
    $cabeca = & git -C $Raiz rev-parse HEAD 2>$null | Select-Object -First 1
    $json = (& gh run list -R $repo --workflow ci --branch $ramo --status success --limit 30 --json 'databaseId,headSha' 2>$null) -join "`n"
    if (-not $json) { Write-Falha 'Não consegui ler as corridas do CI (experimenta: gh auth status).'; return 1 }
    $corridas = $json | ConvertFrom-Json
    $corrida = $corridas | Where-Object { $_.headSha -eq $cabeca } | Select-Object -First 1
    if (-not $corrida) {
        $corrida = $corridas | Select-Object -First 1
        if (-not $corrida) { Write-Falha "Não há nenhuma corrida verde do CI no ramo $ramo."; return 1 }
        Write-Aviso "Não há corrida verde para o commit local; uso a mais recente do ramo ($($corrida.headSha.Substring(0, 7)))."
    }
    $falhou = $false
    foreach ($a in @(@{ Nome = 'empire-windows-debug'; Pasta = 'windows' }, @{ Nome = 'empire-web'; Pasta = 'web' })) {
        $pasta = Join-Path $Build "ci\$($a.Pasta)"
        if (Test-Path $pasta) { Remove-Item -Path $pasta -Recurse -Force }
        Write-Host "  A descarregar $($a.Nome) (corrida $($corrida.databaseId))..."
        & gh run download "$($corrida.databaseId)" -R $repo -n $a.Nome -D $pasta 2>&1 | ForEach-Object { Write-Host "    $_" }
        if ($LASTEXITCODE -ne 0) { Write-Falha "$($a.Nome) não veio (os artifacts do CI expiram)."; $falhou = $true }
        else { Write-Ok "build\ci\$($a.Pasta)" }
    }
    if ($falhou) { return 1 }
    return 0
}

## A mais recente entre a build exportada aqui e a que veio do CI.
function Find-Build([string]$Sub, [string]$Pck) {
    $pastas = @((Join-Path $Build $Sub), (Join-Path $Build "ci\$Sub")) | Where-Object { Test-Path (Join-Path $_ $Pck) }
    return ($pastas | Sort-Object { (Get-Item (Join-Path $_ $Pck)).LastWriteTime } -Descending | Select-Object -First 1)
}

function Invoke-JogarBuild {
    $pasta = Find-Build 'windows' 'empire.pck'
    if (-not $pasta) { Write-Falha 'Não há build de Windows: traz as do CI, ou exporta.'; return 1 }
    $exe = Join-Path $pasta 'empire.console.exe'
    if (-not (Test-Path $exe)) { $exe = Join-Path $pasta 'empire.exe' }
    $argumentos = Get-ArgumentosDeJanela
    if ((Read-Host '  Partida nova? (s/N)') -match '^[sS]') { $argumentos += @('--', '--novo') }
    Restore-SavesPendentes
    Write-Nota "A abrir $exe"
    Show-Controlos
    $log = Get-Log 'build_windows'
    $c = Invoke-Nativo -Exe $exe -Argumentos $argumentos -Log $log -Mostrar '^(Empire |SCRIPT ERROR|ERROR|WARNING|Project FPS)'
    Show-DepoisDoJogo $log
    return $c
}

function Get-PortaLivre([int]$Primeira) {
    for ($p = $Primeira; $p -lt $Primeira + 20; $p++) {
        $escuta = $null
        try {
            $escuta = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
            $escuta.Start()
            return $p
        } catch {
        } finally {
            if ($escuta) { $escuta.Stop() }
        }
    }
    return $Primeira
}

## O preset Web nao usa threads: nao precisa de COOP/COEP, chega o http.server do Python.
function Invoke-JogarWeb {
    $pasta = Find-Build 'web' 'index.pck'
    if (-not $pasta) { Write-Falha 'Não há build Web: traz as do CI, ou exporta.'; return 1 }
    if (-not (Initialize-Python)) { Write-Falha 'Servir a build precisa do Python.'; return 1 }
    $porta = Get-PortaLivre 8000
    $servidor = Start-Process -FilePath $script:Python -PassThru -WindowStyle Minimized -ArgumentList @(
        '-m', 'http.server', "$porta", '--bind', '127.0.0.1', '--directory', "`"$pasta`"")
    Start-Sleep -Milliseconds 900
    Start-Process "http://localhost:$porta/"
    Write-Ok "A servir $pasta em http://localhost:$porta/"
    Write-Nota 'Clica no jogo para lhe dar o foco do teclado. Os saves da versão Web ficam no browser.'
    Read-Host '  Enter para parar o servidor' | Out-Null
    Stop-Process -Id $servidor.Id -ErrorAction SilentlyContinue
    return 0
}
