@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\src\Script.ps1" %*
