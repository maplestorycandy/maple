@chcp 65001 >nul
@echo off
title 楓之谷經典版 - 網頁公網連線隧道
echo ========================================================
echo   正在啟動網頁公網連線 (轉發本地 Port 8910)
echo   稍後下方會出現: https://xxxx.trycloudflare.com
echo   把該網址複製發給網頁版朋友即可連線！
echo ========================================================
echo.
"%~dp0cloudflared.exe" tunnel --url http://localhost:8910
pause
