@chcp 65001 >nul
@echo off
title 楓之谷經典版 - 網頁公網連線隧道 (Cloudflare Tunnel 免設定)

echo ========================================================
echo   楓之谷經典版 ARPG - 網頁版公網連線 (免開 Port / 免 Hamachi)
echo ========================================================
echo.

if not exist "%~dp0cloudflared.exe" (
    echo [1/2] 正在下載輕量級公網穿透工具 (cloudflared.exe)...
    curl.exe -L -o "%~dp0cloudflared.exe" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -#
)

echo [2/2] 正在啟動公網安全連線通道 (轉發至 Port 8910)...
echo.
echo ========================================================
echo 【連線說明】
echo 1. 下方會產生一個 https://xxxx.trycloudflare.com 專屬網址
echo 2. 先在本機打開遊戲「建立房間」(Port: 8910)
echo 3. 把該網址複製給全世界任何打開網頁版的朋友
echo 4. 朋友在網頁版連線框貼上該網址即可秒連進房！
echo ========================================================
echo.

"%~dp0cloudflared.exe" tunnel --url http://localhost:8910

pause
