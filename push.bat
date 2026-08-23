@chcp 65001 >nul
@echo off
title 推送 MapleClassicOnline 至 GitHub (maplestorycandy/maple)
echo 正在推送至 GitHub 倉庫: https://github.com/maplestorycandy/maple ...
git remote set-url origin https://github.com/maplestorycandy/maple.git
git push -u origin main
echo.
pause
