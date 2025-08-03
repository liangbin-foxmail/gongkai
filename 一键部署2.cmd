@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ---------- 0. 写死在脚本里的“配置” ----------
set "PASSWORD=xx1afdsfdsgbbb-----...."
set "URL1=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/gitub_auto005.zip"
set "URL2=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/msedgedriver138.exe"
set "URL3=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/python-3.13.5-amd64.exe"

:: ---------- 1. 桌面路径 ----------
for /f "delims=" %%D in ("%USERPROFILE%\Desktop") do set "DESKTOP=%%~fD"

:: ---------- 2. 下载 aria2c ----------
if not exist "%~dp0aria2c.exe" (
    echo 正在下载 aria2c 多线程下载器...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip' -OutFile '%TEMP%\aria2.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP%\aria2.zip' -DestinationPath '%TEMP%\aria2' -Force"
    copy "%TEMP%\aria2\aria2-1.37.0-win-64bit-build1\aria2c.exe" "%~dp0aria2c.exe" >nul
)

:: ---------- 3. 高速下载 3 个文件 ----------
echo.
echo 使用 aria2c 多线程下载...
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL1%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL2%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL3%"

:: ---------- 4. 7-Zip 带密码解压 ----------
for %%z in ("%URL1%") do set "ZIP_NAME=%%~nz%%~xz"
for %%z in ("%URL1%") do set "FOLDER_NAME=%%~nz"
set "ZIP_PATH=%DESKTOP%\%ZIP_NAME%"
set "FOLDER_PATH=%DESKTOP%\%FOLDER_NAME%"

if exist "%ZIP_PATH%" (
    echo 正在用 7-Zip 解压（密码：%PASSWORD%）
    "C:\Program Files\7-Zip\7z.exe" x -y -p%PASSWORD% -o"%FOLDER_PATH%" "%ZIP_PATH%"
)

:: ---------- 5. 移动 msedgedriver138.exe ----------
if exist "%DESKTOP%\msedgedriver138.exe" (
    move /y "%DESKTOP%\msedgedriver138.exe" "%FOLDER_PATH%\" >nul
)

:: ---------- 6. 检查并安装 Python ----------
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在静默安装 Python...
    "%DESKTOP%\python-3.13.5-amd64.exe" /quiet InstallAllUsers=1 PrependPath=1
    timeout /t 10 /nobreak >nul
)

:: ---------- 7. 刷新环境变量 ----------
timeout /t 5 /nobreak >nul
set "PATH=%PATH%;C:\Program Files\Python313\Scripts;C:\Program Files\Python313"

:: ---------- 8. 验证 Python ----------
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 安装后仍找不到 Python，请重启终端或手动安装
    pause & goto :eof
)

:: ---------- 9. 永久添加腾讯源并信任 ----------
echo [global] > "%APPDATA%\pip\pip.ini"
echo index-url = https://mirrors.cloud.tencent.com/pypi/simple/ >> "%APPDATA%\pip\pip.ini"
echo trusted-host = mirrors.cloud.tencent.com >> "%APPDATA%\pip\pip.ini"

:: ---------- 10. 安装 requirements ----------
if exist "%FOLDER_PATH%\requirements.txt" (
    echo 安装依赖...
    python -m pip install -r "%FOLDER_PATH%\requirements.txt"
)

:: ---------- 11. 打开文件夹 ----------
explorer "%FOLDER_PATH%"
echo ✅ 全部完成
pause

增加两个功能
1.增加静默安装chrome浏览器 138.0.7204
2.解决经常提示未安装python的问题, 第二次运行就可以通过安装python检测


