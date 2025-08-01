@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 获取桌面路径
for /f "tokens=2*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do set DESKTOP=%%j

:: 读取配置文件（简单处理）
set "INI=配置文件.ini"
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

:: 提取干净 URL（去除 XML 标签）
for %%u in ("%URL1%" "%URL2%" "%URL3%") do (
    set "RAW=%%~u"
    set "CLEAN=!RAW:*>=!"
    set "CLEAN=!CLEAN:<*=!"
    if "%%~u"=="%URL1%" set URL1=!CLEAN!
    if "%%~u"=="%URL2%" set URL2=!CLEAN!
    if "%%~u"=="%URL3%" set URL3=!CLEAN!
)

echo.
echo 正在下载文件到桌面: %DESKTOP%
echo.

:: 下载文件
set "ZIP_FILE=gitub_auto001.zip"
set "EXE_FILE=msedgedriver138.exe"
set "PYTHON_INSTALLER=python-3.13.5-amd64.exe"

if not exist "%DESKTOP%\%ZIP_FILE%" (
    powershell -Command "Invoke-WebRequest -Uri '%URL1%' -OutFile '%DESKTOP%\%ZIP_FILE%'"
) else (
    echo 已存在 %ZIP_FILE%，跳过下载。
)

if not exist "%DESKTOP%\%EXE_FILE%" (
    powershell -Command "Invoke-WebRequest -Uri '%URL2%' -OutFile '%DESKTOP%\%EXE_FILE%'"
) else (
    echo 已存在 %EXE_FILE%，跳过下载。
)

if not exist "%DESKTOP%\%PYTHON_INSTALLER%" (
    powershell -Command "Invoke-WebRequest -Uri '%URL3%' -OutFile '%DESKTOP%\%PYTHON_INSTALLER%'"
) else (
    echo 已存在 %PYTHON_INSTALLER%，跳过下载。
)

:: 解压 zip
set "TARGET_DIR=%DESKTOP%\gitub_auto001"
if not exist "%TARGET_DIR%" (
    powershell -Command "Expand-Archive -Path '%DESKTOP%\%ZIP_FILE%' -DestinationPath '%TARGET_DIR%' -Force"
    echo 已解压到 %TARGET_DIR%
) else (
    echo 文件夹已存在，跳过解压。
)

:: 移动 msedgedriver138.exe
for /d %%d in ("%DESKTOP%\gitub_auto*") do (
    move /y "%DESKTOP%\%EXE_FILE%" "%%d\"
)

:: 检查 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 未检测到 Python，正在静默安装...
    "%DESKTOP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1
    echo 等待安装完成...
    timeout /t 10 /nobreak >nul
) else (
    echo Python 已安装，跳过。
)

:: 安装 requirements.txt
for /d %%d in ("%DESKTOP%\gitub_auto*") do (
    if exist "%%d\requirements.txt" (
        echo 正在安装依赖...
        python -m pip install -r "%%d\requirements.txt"
    )
)

:: 打开文件夹
for /d %%d in ("%DESKTOP%\gitub_auto*") do (
    explorer "%%d"
)

echo.
echo ✅ 操作完成，请查看打开的文件夹。
pause
