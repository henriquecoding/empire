# windows/lib/jogo.ps1 - jogar, o editor, e o que fica depois de uma sessao.

function Show-Controlos {
    Write-Host ''
    Write-Host '  Controlos (project.godot)' -ForegroundColor Cyan
    Write-Host '    A/D ou setas   andar                 Espaço          largar moeda (manter: em contínuo)'
    Write-Host '    E              passagem              Botão direito   marcar alvo'
    Write-Host '    Tab            painel de estado      Q / Z           câmara livre      Esc  pausa'
    Write-Host '    Comando: analógico/D-pad, A moeda, X passagem, Y estado, gatilho direito alvo, Start pausa'
    Write-Nota 'Fecha a janela do jogo para voltar aqui.'
    Write-Host ''
}

function Get-ArgumentosDeJanela {
    $a = @()
    if ($script:EcraInteiro) { $a += '--fullscreen' }
    if ($script:MostrarFps) { $a += '--print-fps' }
    return , $a
}

## A semente e o que um relatorio de defeito precisa primeiro (§42, defeito.yml).
function Show-DepoisDoJogo([string]$Log) {
    if (-not (Test-Path $Log)) { return }
    $recibo = Select-String -Path $Log -Pattern '^Empire \W+ semente (\d+)' -Encoding UTF8 | Select-Object -Last 1
    $erros = @(Select-String -Path $Log -Pattern '^(SCRIPT ERROR|USER ERROR|ERROR)' -Encoding UTF8)
    Write-Titulo 'Fim da sessão'
    if ($recibo) { Write-Host "  Semente: $($recibo.Matches[0].Groups[1].Value)" }
    if ($erros.Count -gt 0) { Write-Aviso "$($erros.Count) linha(s) de erro do motor" } else { Write-Ok 'Sem erros do motor.' }
    Write-Nota "Registo: $Log"
    Write-Host ''
    Write-Host '  Saves:'
    Show-Saves
}

function Invoke-Jogar([switch]$Novo) {
    if (-not (Initialize-Godot)) { return 127 }
    Restore-SavesPendentes
    Show-AvisoDeVersao
    $r = Confirm-Importado
    if ($r -ne 0) { return $r }
    $argumentos = @('--path', $Raiz) + (Get-ArgumentosDeJanela)
    if ($Novo) {
        $argumentos += @('--', '--novo')
    } elseif (@(Get-ChildItem -Path $Saves -Filter '*.save' -ErrorAction SilentlyContinue).Count -eq 0) {
        Write-Nota 'Não há autosave: começa uma partida nova.'
    }
    Show-Controlos
    $log = Get-Log 'jogo'
    $c = Invoke-Godot -Argumentos $argumentos -Log $log -Mostrar '^(Empire |SCRIPT ERROR|USER ERROR|ERROR|WARNING|USER WARNING|Project FPS)'
    Show-DepoisDoJogo $log
    return $c
}

function Open-Editor {
    if (-not (Initialize-Godot)) { return 127 }
    Show-AvisoDeVersao -Editor
    Start-Process -FilePath $script:Godot.Janela -WorkingDirectory $Raiz -ArgumentList @('--path', "`"$Raiz`"", '-e')
    Write-Ok 'O editor está a abrir. F5 corre o jogo a partir dele.'
    return 0
}

function Get-UltimoRelatorio {
    $dir = Get-ChildItem -Path (Join-Path $Raiz 'reports') -Directory -Filter 'report_*' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($dir -and (Test-Path (Join-Path $dir.FullName 'index.html'))) { return (Join-Path $dir.FullName 'index.html') }
    return $null
}

function Open-Relatorio {
    $rel = Get-UltimoRelatorio
    if (-not $rel) { Write-Falha 'Ainda não há relatório: corre a suite.'; return 1 }
    Start-Process $rel
    Write-Ok $rel
    return 0
}

function Open-Saves {
    $alvo = $Saves
    if (-not (Test-Path $alvo)) { $alvo = $UserData }
    if (-not (Test-Path $alvo)) { Write-Nota "Ainda não existe ($Saves): o jogo cria-a no primeiro autosave."; return 0 }
    Start-Process explorer.exe -ArgumentList "`"$alvo`""
    Show-Saves
    return 0
}
