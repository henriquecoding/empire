# windows/empire.ps1 - jogar e testar o Empire no Windows, sem make e sem WSL.
#
# Abre-se pelo JOGAR-E-TESTAR.bat da raiz: duplo clique = menu. Tambem aceita um
# comando, para correr sem menu (ver `ajuda`):
#   JOGAR-E-TESTAR.bat jogar | novo | editor | rapida | suite | validar | vistoria 12 ...
#
# Os comandos sao os do Makefile e do .github/workflows/ci.yml, chamados daqui; o
# Makefile continua a ser a fonte. Isto so escreve em build/ e reports/ (os dois no
# .gitignore) e nao muda nenhum ficheiro seguido pelo git. Ver windows/LEIA-ME.md.
#
#   lib/base.ps1         escrever, registos, correr programas, passos e resumo
#   lib/ferramentas.ps1  encontrar o Godot e o Python; o import
#   lib/saves.ps1        os saves de quem joga, postos de lado durante os testes
#   lib/portoes.ps1      os portoes e os instrumentos, um a um
#   lib/builds.ps1       exportar, as builds do CI, joga-las
#   lib/jogo.ps1         jogar, o editor, o fim da sessao
#   lib/estado.ps1       o estado do ambiente, atualizar, o relatorio de defeito
#   lib/menu.ps1         os pacotes de testes e o menu
param(
    [Parameter(Position = 0)][string]$Comando = 'menu',
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Resto = @()
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
# Sem isto, um print com acentos rebenta o portao de Python quando a saida vai para um cano.
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

$Raiz = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Raiz 'build'
$PastaGodot = 'C:\Tools\Godot'
$UserData = Join-Path $env:APPDATA 'Godot\app_userdata\Empire'
$Saves = Join-Path $UserData 'saves'
$SavesGuardados = Join-Path $UserData 'saves_guardados_durante_os_testes'
$SavesDoTeste = Join-Path $UserData 'saves_do_ultimo_teste'
$Ansi = New-Object System.Text.RegularExpressions.Regex('\x1B\[[0-9;?]*[A-Za-z]')

$script:Godot = $null
$script:VersaoGodot = ''
$script:Python = $null
$script:PastaLogs = Join-Path $Build 'logs'
$script:EcraInteiro = $false
$script:MostrarFps = $false
$script:Resultados = New-Object System.Collections.Generic.List[object]

foreach ($modulo in @('base', 'ferramentas', 'saves', 'portoes', 'builds', 'jogo', 'estado', 'menu')) {
    . (Join-Path $Raiz "windows\lib\$modulo.ps1")
}

function Show-Ajuda {
    Write-Host @'
Uso: JOGAR-E-TESTAR.bat [comando]      (sem comando abre o menu)

  jogar        continuar a partida          novo         partida nova (--novo)
  editor       abrir no editor Godot        rapida       verificação rápida
  suite        suite gdUnit4                validar      validação completa
  vistoria N   vistoria de N dias (8)       noite        cenário da noite
  dez-dias     as defesas até ao dia 10     fotos        fotografias manhã/noite
  relatorio    último relatório gdUnit4     builds-ci    descarregar builds do CI
  build        jogar a build de Windows     web          jogar a build Web
  exportar     exportar Windows e Web       estado       estado do ambiente
  saves        pasta dos saves              atualizar    git pull + import
  defeito      relatório de defeito         python       instalar gdtoolkit e pillow

Os comandos de teste devolvem 0 quando nada falhou.
'@
}

function Invoke-Comando([string]$Nome, [string[]]$Extra = @()) {
    $n = $Nome.ToLower()
    $ajudas = @('ajuda', 'help', '-h', '--help', '/?')
    if ($n -notin $ajudas) { Confirm-PastasIgnoradas }
    if ($n -notin ($ajudas + @('menu'))) { Start-Accao $n }
    switch ($n) {
        'menu' { return (Show-Menu) }
        'jogar' { return (Invoke-Jogar) }
        'novo' { return (Invoke-Jogar -Novo) }
        'editor' { return (Open-Editor) }
        'rapida' { return (Invoke-VerificacaoRapida) }
        'suite' { return (Invoke-SoSuite) }
        'validar' { return (Invoke-ValidacaoCompleta) }
        'vistoria' {
            $dias = 8
            if ($Extra.Count -gt 0 -and $Extra[0] -match '^\d+$') { $dias = [int]$Extra[0] }
            return (Invoke-Instrumento "Vistoria: $dias dias vigiados" ([scriptblock]::Create("Test-Vistoria $dias")))
        }
        'noite' { return (Invoke-Instrumento 'Cenário da noite (night_test)' { Test-Noite }) }
        'dez-dias' { return (Invoke-Instrumento 'Dez dias (dez_dias)' { Test-DezDias }) }
        'fotos' { return (Invoke-Fotos) }
        'relatorio' { return (Open-Relatorio) }
        'builds-ci' { return (Save-BuildsDoCI) }
        'build' { return (Invoke-JogarBuild) }
        'web' { return (Invoke-JogarWeb) }
        'exportar' {
            $script:Resultados.Clear()
            Invoke-Passo 'Importar recursos' { Confirm-Importado }
            Invoke-Passo 'Export de Windows e Web' { Invoke-Exportar }
            return (Show-Resultados 'Exportar')
        }
        'estado' { return (Show-Estado) }
        'saves' { return (Open-Saves) }
        'atualizar' { return (Update-Projeto) }
        { $_ -in @('defeito', 'bug') } { return (New-RelatorioDeBug) }
        'python' { return (Install-FerramentasPython) }
        { $_ -in $ajudas } { Show-Ajuda; return 0 }
        default { Write-Falha "Comando desconhecido: $Nome"; Show-Ajuda; return 2 }
    }
}

$codigo = Invoke-Comando $Comando $Resto
if ($codigo -is [array]) { $codigo = $codigo[-1] }
if ("$codigo" -match '^\d+$') { exit [int]$codigo }
exit 0
