@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 正确获取桌面路径
for /f "tokens=2*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop 2^>nul') do set "DESKTOP=%%j"
if not defined DESKTOP set "DESKTOP=%USERPROFILE%\Desktop"

:: 配置文件路径
set "INI=%~dp0配置文件.ini"
:: 默认值
set "PASSWORD="
set "URL1="
set "URL2="
set "URL3="

:: 读取 INI
for /f "usebackq tokens=1,* delims==" %%a in ("%INI%") do (
    set "LINE=%%a"
    set "VALUE=%%b"
    if "!LINE:密码=!" neq "!LINE!" set "PASSWORD=!VALUE!"
    if "!LINE:下载地址1=!" neq "!LINE!" set "URL1=!VALUE!"
    if "!LINE:下载地址2=!" neq "!LINE!" set "URL2=!VALUE!"
    if "!LINE:下载地址3=!" neq "!LINE!" set "URL3=!VALUE!"
)

:: 提取干净 URL
for %%u in ("%URL1%" "%URL2%" "%URL3%") do (
    set "RAW=%%~u"
    set "CLEAN=!RAW:*>=!"
    set "CLEAN=!CLEAN:<*=!"
    if "%%~u"=="%URL1%" set URL1=!CLEAN!
    if "%%~u"=="%URL2%" set URL2=!CLEAN!
    if "%%~u"=="%URL3!" set URL3=!CLEAN!
)

:: 下载 aria2c（如不存在）
if not exist "%~dp0aria2c.exe" (
    echo 正在下载 aria2c ...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip' -OutFile '%TEMP%\aria2.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP%\aria2.zip' -DestinationPath '%TEMP%\aria2' -Force"
    copy "%TEMP%\aria2\aria2-1.37.0-win-64bit-build1\aria2c.exe" "%~dp0aria2c.exe" >nul
)

:: 使用 aria2c 多线程下载
echo 正在高速下载文件...
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL1%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL2%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL3%"

:: 获取 zip 文件名与目标文件夹名
for %%z in ("%URL1%") do set "ZIP_NAME=%%~nz%%~xz"
for %%z in ("%URL1%") do set "FOLDER_NAME=%%~nz"
set "ZIP_PATH=%DESKTOP%\%ZIP_NAME%"
set "FOLDER_PATH=%DESKTOP%\%FOLDER_NAME%"

:: 7-Zip 带密码解压
if exist "%ZIP_PATH%" (
    echo 使用 7-Zip 解压（密码：%PASSWORD%）
    "C:\Program Files\7-Zip\7z.exe" x -y -p%PASSWORD% -o"%FOLDER_PATH%" "%ZIP_PATH%"
)

:: 移动 msedgedriver138.exe 到目标文件夹
move /y "%DESKTOP%\msedgedriver138.exe" "%FOLDER_PATH%\"

:: 检查并安装 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在静默安装 Python...
    "%DESKTOP%\python-3.13.5-amd64.exe" /quiet InstallAllUsers=1 PrependPath=1
    timeout /t 10 /nobreak >nul
)

:: 安装 requirements.txt
if exist "%FOLDER_PATH%\requirements.txt" (
    echo 安装 Python 依赖...
    python -m pip install -r "%FOLDER_PATH%\requirements.txt"
)

:: 打开目录
explorer "%FOLDER_PATH%"

echo ✅ 全部完成
pause
