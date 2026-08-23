@chcp 65001 >nul
@echo off
title 推送 MapleClassicOnline 至 GitHub
echo 正在推送至 GitHub 倉庫 (https://github.com/maplestorycandy/maple)...
echo.
git remote set-url origin https://github.com/maplestorycandy/maple.git
git push -u origin main
echo.
echo ========================================================
echo 若推送成功，GitHub Actions 將自動進行 Web 編譯
echo 並自動部署至 GitHub Pages:
echo https://maplestorycandy.github.io/maple/
echo ========================================================
pause
