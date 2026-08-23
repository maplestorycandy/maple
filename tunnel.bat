@chcp 65001 >nul
@echo off
cloudflared.exe tunnel --url http://localhost:8910
pause
