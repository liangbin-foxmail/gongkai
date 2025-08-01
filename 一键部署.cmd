@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ---------- 正确桌面路径 ----------
for /f "delims=" %%D in ("%USERPROFILE%\Desktop") do set "DESKTOP=%%~fD"


:: ---------- 2. 读取配置文件 ----------
set "INI=%~dp0配置文件.ini"
set "PASSWORD="
set "URL1="
set "URL2="
set "URL3="

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
    if "%%~u"=="%URL3%" set URL3=!CLEAN!
)

:: ---------- 3. 下载 aria2c ----------
if not exist "%~dp0aria2c.exe" (
    echo 正在下载 aria2c 多线程下载器...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip' -OutFile '%TEMP%\aria2.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP%\aria2.zip' -DestinationPath '%TEMP%\aria2' -Force"
    copy "%TEMP%\aria2\aria2-1.37.0-win-64bit-build1\aria2c.exe" "%~dp0aria2c.exe" >nul
)

:: ---------- 4. 高速下载文件 ----------
echo.
echo 使用 aria2c 多线程下载...
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL1%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL2%"
"%~dp0aria2c.exe" -x16 -s16 -k1M -d "%DESKTOP%" "%URL3%"

:: ---------- 5. 7-Zip 带密码解压 ----------
for %%z in ("%URL1%") do set "ZIP_NAME=%%~nz%%~xz"
for %%z in ("%URL1%") do set "FOLDER_NAME=%%~nz"
set "ZIP_PATH=%DESKTOP%\%ZIP_NAME%"
set "FOLDER_PATH=%DESKTOP%\%FOLDER_NAME%"

if exist "%ZIP_PATH%" (
    echo 正在用 7-Zip 解压（密码：%PASSWORD%）
    "C:\Program Files\7-Zip\7z.exe" x -y -p%PASSWORD% -o"%FOLDER_PATH%" "%ZIP_PATH%"
)

:: ---------- 6. 移动 msedgedriver138.exe ----------
move /y "%DESKTOP%\msedgedriver138.exe" "%FOLDER_PATH%\"

:: ---------- 7. 检查并安装 Python ----------
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在静默安装 Python...
    "%DESKTOP%\python-3.13.5-amd64.exe" /quiet InstallAllUsers=1 PrependPath=1
    timeout /t 10 /nobreak >nul
)


:: ---------- -. 刷新环境变量 ----------
echo 刷新环境变量...
set "PATH=%PATH%;C:\Program Files\Python313\Scripts;C:\Program Files\Python313"

:: ---------- -. 验证 Python ----------
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 安装后仍找不到 Python，请重启终端或手动安装
    pause & goto :eof
)


:: ---------- 8. 永久添加腾讯源并信任 ----------
echo [global] > "%APPDATA%\pip\pip.ini"
echo index-url = https://mirrors.cloud.tencent.com/pypi/simple/ >> "%APPDATA%\pip\pip.ini"
echo trusted-host = mirrors.cloud.tencent.com >> "%APPDATA%\pip\pip.ini"

:: ---------- 9. 安装 requirements ----------
if exist "%FOLDER_PATH%\requirements.txt" (
    echo 安装依赖...
    python -m pip install -r "%FOLDER_PATH%\requirements.txt"
)

:: ---------- 10. 打开文件夹 ----------
explorer "%FOLDER_PATH%"
echo ✅ 全部完成
pause
