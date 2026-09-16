# windows/lib/estado.ps1 - o estado do ambiente, atualizar, e o relatorio de defeito.

function Show-Estado {
    Write-Titulo 'Projeto'
    Write-Host "  Pasta   : $Raiz"
    Write-Host ('  Ramo    : ' + (& git -C $Raiz branch --show-current 2>$null | Select-Object -First 1))
    Write-Host ('  Commit  : ' + (& git -C $Raiz log -1 --format='%h  %s  (%cr)' 2>$null | Select-Object -First 1))
    $alteracoes = @(& git -C $Raiz status --porcelain --untracked-files=no 2>$null)
    if ($alteracoes.Count -eq 0) { Write-Ok 'Nenhum ficheiro do projeto alterado.' }
    else {
        Write-Aviso "$($alteracoes.Count) ficheiro(s) do projeto alterado(s):"
        $alteracoes | Select-Object -First 12 | ForEach-Object { Write-Host "    $_" }
    }

    Write-Titulo 'Ferramentas'
    if (Initialize-Godot) {
        Write-Host "  Godot     : $($script:VersaoGodot)"
        Write-Nota $script:Godot.Consola
        if (Test-VersaoFixada) { Write-Ok "É a versão fixada ($(Get-VersaoFixada))." } else { Show-AvisoDeVersao }
        $t = Get-PastaTemplates
        if ($t -and (Test-Path $t)) { Write-Host "  Templates : $t" }
        else { Write-Host "  Templates : não ($t) - exportar aqui não está disponível" }
    }
    if (Initialize-Python) {
        $v = & $script:Python --version 2>&1 | Select-Object -First 1
        Write-Host "  Python    : $v"
        Write-Host ('  Pillow    : ' + $(if (Test-ModuloPython 'PIL') { 'sim' } else { 'não - a silhueta fica por contar' }))
        Write-Host ('  gdtoolkit : ' + $(if (Test-ModuloPython 'gdtoolkit') { 'sim' } else { 'não - formato e estilo ficam por correr' }))
    } else { Write-Host '  Python    : não encontrado' }
    Write-Host ('  gh        : ' + $(if (Get-Command gh -ErrorAction SilentlyContinue) { 'sim' } else { 'não - as builds do CI não se descarregam daqui' }))
    Write-Host ('  Node      : ' + $(if (Get-Command node -ErrorAction SilentlyContinue) { (& node --version 2>$null) } else { 'não' }))

    Write-Titulo 'Builds'
    foreach ($b in @('windows\empire.pck', 'web\index.pck', 'ci\windows\empire.pck', 'ci\web\index.pck')) {
        $f = Join-Path $Build $b
        if (Test-Path $f) { Write-Host ('  build\{0,-22} {1:dd/MM HH:mm}' -f (Split-Path -Parent $b), (Get-Item $f).LastWriteTime) }
        else { Write-Host ('  build\{0,-22} -' -f (Split-Path -Parent $b)) }
    }

    Write-Titulo "Saves ($Saves)"
    Show-Saves
    $rel = Get-UltimoRelatorio
    if ($rel) { Write-Titulo 'Último relatório do gdUnit4'; Write-Host "  $rel" }
    return 0
}

## Os ficheiros que o EDITOR do Godot reescreve sozinho quando abre o projeto
## numa versao diferente da fixada. Nao sao trabalho de ninguem: sao ruido do
## motor, e sao a razao numero um de um `atualizar` que se recusa a andar.
$script:RuidoDoMotor = @('project.godot')

## O ramo que o CI mede e onde o trabalho aterra. Um `git pull` num ramo antigo
## corre sem erro e nao traz nada — e e assim que se fica a olhar para um jogo
## de ontem a jurar que se atualizou.
$script:RamoDeTrabalho = 'main'


function Update-Projeto {
    $ramo = (& git -C $Raiz branch --show-current 2>$null | Select-Object -First 1)
    $antes = (& git -C $Raiz rev-parse --short HEAD 2>$null | Select-Object -First 1)
    Write-Host "  Ramo   : $ramo"
    Write-Host "  Commit : $antes"

    if ($ramo -and $ramo -ne $script:RamoDeTrabalho) {
        Write-Falha "Estas no ramo '$ramo' e o trabalho aterra em '$($script:RamoDeTrabalho)'."
        Write-Nota "Um pull aqui corre sem erro e nao traz nada. Para mudar:"
        Write-Nota "  git -C `"$Raiz`" checkout $($script:RamoDeTrabalho)"
        return 1
    }

    $alteracoes = @(& git -C $Raiz status --porcelain --untracked-files=no 2>$null)
    if ($alteracoes.Count -gt 0) {
        # Separar o ruido do motor do que e mesmo trabalho: a mensagem que diz
        # "ha ficheiros alterados" sem dizer QUAIS e porque manda a pessoa
        # procurar sozinha uma coisa que nao foi ela que fez.
        $mexidos = $alteracoes | ForEach-Object { ($_ -replace '^..\s+', '').Trim() }
        $trabalho = @($mexidos | Where-Object { $script:RuidoDoMotor -notcontains $_ })
        Write-Falha 'Ha ficheiros do projeto alterados; nao atualizo para nao os perder:'
        $mexidos | Select-Object -First 12 | ForEach-Object { Write-Host "    $_" }
        if ($trabalho.Count -eq 0) {
            Write-Aviso 'Isto e ruido do motor e nao trabalho teu: foi o editor do Godot a'
            Write-Nota 'reescrever o projeto ao abri-lo numa versao diferente da fixada'
            Write-Nota "($(Get-VersaoFixada), em .godot-version). Podes deitar fora sem perder nada:"
            foreach ($f in $mexidos) { Write-Nota "  git -C `"$Raiz`" checkout -- $f" }
        }
        else {
            Write-Nota 'Para os guardar antes: git stash (e depois git stash pop).'
        }
        return 1
    }

    & git -C $Raiz pull --ff-only 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) {
        Write-Falha 'O git pull nao avancou (ver acima).'
        Write-Nota 'Se o ramo divergiu, o --ff-only recusa de proposito. Ve com:'
        Write-Nota "  git -C `"$Raiz`" log --oneline --graph HEAD...origin/$($script:RamoDeTrabalho)"
        return 1
    }

    # Dizer o que mudou, e nao so que correu. "Ja estava atualizado" e uma
    # resposta; ficar sem resposta nenhuma manda a pessoa abrir o jogo para
    # descobrir, e foi isso que custou uma sessao a alguem.
    $depois = (& git -C $Raiz rev-parse --short HEAD 2>$null | Select-Object -First 1)
    if ($antes -eq $depois) {
        Write-Ok "Ja estavas na ponta do '$($script:RamoDeTrabalho)' ($depois) — nada para trazer."
    }
    else {
        $quantos = @(& git -C $Raiz log --oneline "$antes..$depois" 2>$null).Count
        Write-Ok "$antes -> $depois ($quantos commit(s) novo(s)):"
        & git -C $Raiz log --oneline "$antes..$depois" 2>$null |
            Select-Object -First 10 | ForEach-Object { Write-Host "    $_" }
    }
    return (Confirm-Importado -Forcar)
}

## Os campos do .github/ISSUE_TEMPLATE/defeito.yml, ja com o que se sabe sem
## perguntar: o commit, o Godot, o sistema, e a semente e os erros do ultimo jogo.
function New-RelatorioDeBug {
    $null = Initialize-Godot
    $pasta = Join-Path $Build 'defeitos'
    New-Item -ItemType Directory -Force -Path $pasta | Out-Null
    $ultimo = Get-ChildItem -Path (Join-Path $Build 'logs') -Recurse -Filter '*.log' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @('jogo.log', 'build_windows.log') } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $semente = 'não aplicável'
    $recibo = ''
    $erros = @()
    if ($ultimo) {
        $linha = Select-String -Path $ultimo.FullName -Pattern '^Empire \W+ semente (\d+).*$' -Encoding UTF8 | Select-Object -Last 1
        if ($linha) { $semente = $linha.Matches[0].Groups[1].Value; $recibo = $linha.Line }
        $erros = @(Select-String -Path $ultimo.FullName -Pattern '^(SCRIPT ERROR|USER ERROR|ERROR)' -Encoding UTF8 |
            Select-Object -First 15 | ForEach-Object { '    ' + $_.Line })
    }
    $doExport = ($ultimo -and $ultimo.Name -eq 'build_windows.log')
    $noEditor = $(if ($ultimo -and -not $doExport) { 'x' } else { ' ' })
    $noExport = $(if ($doExport) { 'x' } else { ' ' })
    $repo = Get-RepositorioGitHub
    $onde = $(if ($repo) { "https://github.com/$repo/issues/new?template=defeito.yml" } else { 'o modelo "Defeito" no GitHub' })
    $ficheiro = Join-Path $pasta ('defeito-' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '.md')
    $texto = @"
<!-- Os campos do modelo Defeito: $onde -->
# <título curto: o que faz o que não devia>

## Semente
$semente

## Dia, fase e tick
<o painel do Tab mostra os três>

## Como se reproduz
1.
2.
3.

## O que devia acontecer, e o que acontece
<se a spec diz uma coisa e o jogo faz outra, cita a secção; se a spec não cobre o caso,
isto é uma pergunta para docs/QUESTIONS.md e não um defeito>

## Versão ou commit
$(& git -C $Raiz log -1 --format='%h (%cd)' --date=short 2>$null) no ramo $(& git -C $Raiz branch --show-current 2>$null)
Godot $($script:VersaoGodot) (fixado: $(Get-VersaoFixada)) · $((Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption)

## Onde corre
- [$noEditor] Editor do Godot
- [ ] Export de Linux
- [$noExport] Export de Windows
- [ ] Steam Deck
- [ ] Suite de testes / CI

## Registo do motor
$(if ($ultimo) { $ultimo.FullName } else { '(ainda não há registo de nenhuma sessão de jogo)' })
$recibo
$($erros -join "`r`n")
"@
    Set-Content -Path $ficheiro -Value $texto -Encoding UTF8
    Start-Process notepad.exe -ArgumentList "`"$ficheiro`""
    Write-Ok $ficheiro
    return 0
}

function Install-FerramentasPython {
    if (-not (Initialize-Python)) { Write-Falha 'Não encontrei o Python.'; return 1 }
    Write-Host '  Instala do PyPI, nas versões fixadas em tools\requirements.txt:'
    Get-Content (Join-Path $Raiz 'tools\requirements.txt') | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { Write-Host "    $_" }
    Write-Nota 'gdtoolkit: formato e estilo do GDScript. pillow: contar os píxeis da silhueta.'
    if ((Read-Host '  Instalar? (s/N)') -notmatch '^[sS]') { return 0 }
    return (Invoke-Python -Argumentos @('-m', 'pip', 'install', '--user', '-r', 'tools/requirements.txt') -Log (Get-Log 'pip'))
}
