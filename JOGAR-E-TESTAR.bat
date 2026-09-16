@echo off
rem Empire - jogar e testar no Windows. Duplo clique abre o menu; ver windows\LEIA-ME.md
rem Aceita um comando: JOGAR-E-TESTAR.bat ajuda
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\empire.ps1" %*
if errorlevel 1 pause
