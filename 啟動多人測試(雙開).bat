@echo off
title 楓之谷經典版 - 多人連線雙開測試 (Host + Client)
echo 正在啟動 [視窗 1: 房主 Host]...
start "MapleStory Host" "%~dp0Godot_v4.3-stable_win64.exe" --path "%~dp0."

timeout /t 2 /nobreak >nul

echo 正在啟動 [視窗 2: 隊員 Client]...
start "MapleStory Client" "%~dp0Godot_v4.3-stable_win64.exe" --path "%~dp0."
