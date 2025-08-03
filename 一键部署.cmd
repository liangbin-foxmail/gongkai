@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ---------- 0. 写死在脚本里的“配置” ----------
set "PASSWORD=xx1afdsfdsgbbb-----...."
set "URL1=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/gitub_auto005.zip"
set "URL2=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/msedgedriver138.exe"
set "URL3=https://raw.githubusercontent.com/liangbin-foxmail/gongkai/main/python-3.13.5-amd64.exe"
set "CHROME_URL=https://dl.google.com/chrome/install/138.0.7204.0/googlechromestandaloneenterprise64.msi"

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
set "ZIP_NAME=gitub_auto005.zip"
set "FOLDER_NAME=gitub_auto005"
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

:: ---------- 6. 静默安装 Chrome ----------
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在静默安装 Chrome 138.0.7204 ...
    "%~dp0aria2c.exe" -x16 -s16 -k1M -d "%TEMP%" "%CHROME_URL%"
    msiexec /i "%TEMP%\googlechromestandaloneenterprise64.msi" /qn /norestart
)

:: ---------- 7. 检查并安装 Python ----------
:: 先刷新一次环境变量，避免第一次装完后脚本仍检测不到
call :RefreshEnv
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在静默安装 Python...
    "%DESKTOP%\python-3.13.5-amd64.exe" /quiet InstallAllUsers=1 PrependPath=1
    timeout /t 10 /nobreak >nul
    call :RefreshEnv
)

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
goto :eof

:: ---------- 子函数：刷新环境变量 ----------
:RefreshEnv
:: 通过 powershell 重新加载系统 PATH 到当前进程
powershell -NoLogo -NoProfile -Command ^
  "$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH','User')"
exit /b
