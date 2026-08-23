@chcp 65001 >nul
@echo off
title 楓之谷經典版 - 網頁公網連線隧道
"%~dp0cloudflared.exe" tunnel --url http://localhost:8910
pause
