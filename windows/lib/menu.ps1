# windows/lib/menu.ps1 - os pacotes de testes, e o menu.

function Invoke-VerificacaoRapida {
    $script:Resultados.Clear()
    Invoke-ComSavesProtegidos {
        Invoke-Passo 'Importar recursos' { Confirm-Importado }
        Invoke-Passo 'Arranque: o boot entrega a cena de jogo' { Test-Arranque }
        Invoke-Passo 'Dados: CSV e .tres em sincronia' { Test-Dados }
        Invoke-Passo 'Lint da simulação (G1 G2 G4 G6)' { Test-LintSim }
        Invoke-Passo 'G2: nenhum RNG fora do RngService' { Test-Rng }
    }
    return (Show-Resultados 'Verificação rápida')
}

function Invoke-SoSuite {
    $script:Resultados.Clear()
    Invoke-ComSavesProtegidos {
        Invoke-Passo 'Importar recursos' { Confirm-Importado }
        Invoke-Passo 'Suite gdUnit4' { Test-Suite }
    }
    return (Show-Resultados 'Suite gdUnit4')
}

## Os jobs do ci.yml pela mesma ordem, menos o que precisa de Linux.
function Invoke-ValidacaoCompleta {
    $script:Resultados.Clear()
    if (-not (Initialize-Godot)) { return 1 }
    Show-AvisoDeVersao
    Invoke-ComSavesProtegidos {
        Invoke-Passo 'Importar recursos' { Confirm-Importado -Forcar }
        Invoke-Passo 'Formato do GDScript (gdformat)' { Test-Formato }
        Invoke-Passo 'Estilo e limite de 250 linhas (gdlint)' { Test-Estilo }
        Invoke-Passo 'G2: nenhum RNG fora do RngService' { Test-Rng }
        Invoke-Passo 'Números do dossiê contra os CSV' { Test-DossieNumeros }
        Invoke-Passo 'Conteúdo: SCHEMA, PROPOSALS, ROT_BY_DAY, NAMES' { Test-Conteudo }
        Invoke-Passo 'Spec: docs/design gerado do dossiê' { Test-Spec }
        Invoke-Passo 'Afirmações contra a contagem real' { Test-Afirmacoes }
        Invoke-Passo 'Dados: CSV e .tres em sincronia' { Test-Dados }
        Invoke-Passo 'Lint da simulação (G1 G2 G4 G6)' { Test-LintSim }
        Invoke-Passo 'Suite gdUnit4' { Test-Suite }
        Invoke-Passo 'Vistoria: 8 dias vigiados' { Test-Vistoria 8 }
        Invoke-Passo 'Cenário da noite (night_test)' { Test-Noite }
        Invoke-Passo 'Dez dias (dez_dias)' { Test-DezDias }
        Invoke-Passo 'Arranque: o boot entrega a cena de jogo' { Test-Arranque }
        Invoke-Passo 'Silhueta: a noite e as duas frias (§80)' { Test-Silhueta }
        Invoke-Passo 'Export de Windows e Web' { Invoke-Exportar }
        Invoke-Passo 'Camada de uso do dossiê' { Test-CamadaDossie }
    }
    Write-Nota 'Fora daqui: o actionlint (binário de Linux) e o export de Linux, que o CI corre.'
    return (Show-Resultados 'Validação completa')
}

function Invoke-Fotos {
    $script:Resultados.Clear()
    Invoke-ComSavesProtegidos {
        Invoke-Passo 'Importar recursos' { Confirm-Importado }
        Invoke-Passo 'Fotografia do meio da manhã' { Invoke-Foto 'manha' }
        Invoke-Passo 'Fotografia do meio da noite + silhueta' { Test-Silhueta }
    }
    $falhas = Show-Resultados 'Fotografias'
    foreach ($p in @('manha', 'noite')) {
        $png = Join-Path $Build "capturas\$p.png"
        if (Test-Path $png) { Start-Process $png }
    }
    return $falhas
}

function Invoke-Instrumento([string]$Titulo, [scriptblock]$Teste) {
    $script:Resultados.Clear()
    Invoke-ComSavesProtegidos {
        Invoke-Passo 'Importar recursos' { Confirm-Importado }
        Invoke-Passo $Titulo $Teste
    }
    return (Show-Resultados $Titulo)
}

function Show-Cabecalho {
    $ramo = & git -C $Raiz branch --show-current 2>$null | Select-Object -First 1
    $commit = & git -C $Raiz rev-parse --short HEAD 2>$null | Select-Object -First 1
    Write-Host ''
    Write-Host '  EMPIRE - jogar e testar' -ForegroundColor Cyan
    Write-Host "  $Raiz  ($ramo @ $commit)" -ForegroundColor DarkGray
    if (Initialize-Godot) {
        $cor = 'DarkGray'
        $extra = ''
        if (-not (Test-VersaoFixada)) { $cor = 'Yellow'; $extra = "  (fixado: $(Get-VersaoFixada))" }
        Write-Host "  Godot $(($script:VersaoGodot -split '\.official')[0])$extra" -ForegroundColor $cor
    }
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Show-Cabecalho
        $janela = '{0,-16}' -f $(if ($script:EcraInteiro) { 'ecrã inteiro' } else { 'janela' })
        $fps = if ($script:MostrarFps) { 'sim' } else { 'não' }
        Write-Host @"

  JOGAR
     1  Continuar a partida ........ retoma o autosave mais recente
     2  Partida nova ............... ignora o autosave (--novo)
     3  Abrir no editor Godot
     J  Modo: $janela F  FPS na consola: $fps

  TESTAR                                                        (os saves ficam protegidos)
     4  Verificação rápida ......... arranque, dados, lint, RNG             ~15 s
     5  Suite gdUnit4 .............. a suite inteira                         ~1,5 min
     6  Validação completa ......... o que o CI corre e cabe no Windows      ~4 min
     7  Vistoria ................... N dias do greybox vigiados tick a tick
     8  Cenário da noite ........... dez noites, com e sem torre              ~25 s
     9  Dez dias ................... as defesas varridas até ao dia 10       ~2 min
    10  Fotografias ................ meio da manhã e meio da noite (abre-as)
    11  Último relatório do gdUnit4

  BUILDS
    12  Descarregar as builds do CI (Windows + Web, via gh)
    13  Jogar a build de Windows
    14  Jogar a build Web no browser
    15  Exportar aqui (precisa dos templates de export)

  OUTROS
    16  Estado do ambiente             17  Pasta dos saves
    18  Atualizar o projeto (git pull) 19  Relatório de defeito pré-preenchido
    20  Instalar ferramentas Python     0  Sair

"@
        $entrada = Read-Host '  Escolhe'
        if ($null -eq $entrada) { return 0 }
        $escolha = $entrada.Trim().ToUpper()
        if ($escolha -eq '0' -or $escolha -eq 'Q') { return 0 }
        if ($escolha -eq 'J') { $script:EcraInteiro = -not $script:EcraInteiro; continue }
        if ($escolha -eq 'F') { $script:MostrarFps = -not $script:MostrarFps; continue }
        $nome = switch ($escolha) {
            '1' { 'jogar' } '2' { 'novo' } '3' { 'editor' } '4' { 'rapida' } '5' { 'suite' }
            '6' { 'validar' } '7' { 'vistoria' } '8' { 'noite' } '9' { 'dez-dias' } '10' { 'fotos' }
            '11' { 'relatorio' } '12' { 'builds-ci' } '13' { 'build' } '14' { 'web' } '15' { 'exportar' }
            '16' { 'estado' } '17' { 'saves' } '18' { 'atualizar' } '19' { 'defeito' } '20' { 'python' }
            default { '' }
        }
        if (-not $nome) { continue }
        $extra = @()
        if ($nome -eq 'vistoria') {
            $dias = (Read-Host '  Quantos dias? (Enter = 8)').Trim()
            if ($dias -match '^\d+$') { $extra = @($dias) }
        }
        $null = Invoke-Comando $nome $extra
        Write-Host ''
        Read-Host '  Enter para voltar ao menu' | Out-Null
    }
}
