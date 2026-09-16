# windows/lib/saves.ps1 - os saves de quem joga.
#
# A suite grava e apaga slots em user://saves (tests/save_service_test.gd), que e a
# mesma pasta das partidas: enquanto os testes correm, a pasta sai para o lado.

## Uma corrida de testes fechada no X nao chega ao `finally`: os saves ficam de lado
## ate a proxima vez que isto abre. Nada e apagado; um conflito vai para outra pasta.
function Restore-SavesPendentes {
    if (-not (Test-Path $SavesGuardados)) { return }
    if (Test-Path $Saves) {
        $lado = Join-Path $UserData ('saves_conflito_' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
        Move-Item -Path $Saves -Destination $lado
        Write-Aviso "Uma corrida de testes foi interrompida; o que estava em saves foi para $lado"
    }
    Move-Item -Path $SavesGuardados -Destination $Saves
    Write-Ok 'Os teus saves, postos de lado por uma corrida de testes interrompida, voltaram.'
}

function Invoke-ComSavesProtegidos([scriptblock]$Trabalho) {
    Restore-SavesPendentes
    $havia = Test-Path $Saves
    $slots = @(Get-ChildItem -Path $Saves -Filter '*.save' -ErrorAction SilentlyContinue).Count
    if ($havia) {
        try { Move-Item -Path $Saves -Destination $SavesGuardados -ErrorAction Stop }
        catch {
            Write-Falha "Não consegui pôr os saves de lado (o jogo está aberto?): $($_.Exception.Message)"
            $script:Resultados.Add([pscustomobject]@{
                    Passo = 'Pôr os saves de lado'; Resultado = 'FALHOU'; Segundos = 0; Nota = 'fecha o jogo e repete' })
            return
        }
        if ($slots -gt 0) { Write-Nota "Os teus $slots save(s) ficam de lado enquanto os testes correm (a suite apaga os slots)." }
    }
    try {
        & $Trabalho
    } finally {
        if (Test-Path $SavesDoTeste) { Remove-Item -Path $SavesDoTeste -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path $Saves) { Move-Item -Path $Saves -Destination $SavesDoTeste -ErrorAction SilentlyContinue }
        if ($havia) {
            Move-Item -Path $SavesGuardados -Destination $Saves -ErrorAction SilentlyContinue
            if (-not (Test-Path $Saves)) { Write-Falha "Não consegui repor os saves: estão em $SavesGuardados" }
            elseif ($slots -gt 0) { Write-Ok "Os teus $slots save(s) voltaram ao sítio." }
        }
    }
}

function Show-Saves {
    $slots = @(Get-ChildItem -Path $Saves -Filter '*.save' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($slots.Count -eq 0) {
        Write-Nota 'Ainda não há autosave. Grava-se na alvorada, a partir do dia 2.'
        return
    }
    foreach ($s in $slots) {
        Write-Host ('  {0,-12} {1:dd/MM HH:mm:ss}  {2,5:N0} KB' -f $s.Name, $s.LastWriteTime, ($s.Length / 1KB))
    }
}
