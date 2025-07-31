@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 1. 获取桌面路径
for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop') do set "DESKTOP=%%b"
echo 桌面路径：%DESKTOP%

:: 2. 读取配置文件
set "CONFIG_FILE=%~dp0配置文件.ini"
if not exist "%CONFIG_FILE%" (
    echo 错误：找不到配置文件 "%CONFIG_FILE%"
    echo 请确保配置文件与脚本在同一目录下
    pause & exit /b 1
)

:: 读取密码和下载地址
set "PASSWORD="
set "DOWNLOAD_URLS="
set "URL_COUNT=0"
set "IN_DEFAULT_SECTION=0"

:: 逐行读取配置文件并解析
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do (
    set "LINE=%%a"

    :: 检查是否是节标题
    if "!LINE:~0,1!"=="[" (
        if "!LINE!"=="[DEFAULT]" (
            set "IN_DEFAULT_SECTION=1"
        ) else (
            set "IN_DEFAULT_SECTION=0"
        )
    ) else if !IN_DEFAULT_SECTION! equ 1 (
        :: 处理键值对
        for /f "tokens=1,* delims==" %%b in ("!LINE!") do (
            set "KEY=%%b"
            set "VALUE=%%c"

            :: 清理键名前后的空格
            for /f "tokens=* delims= " %%k in ("!KEY!") do set "KEY=%%k"

            if "!KEY!"=="密码" (
                set "PASSWORD=!VALUE!"
                :: 清理密码前后的空格和句点
                for /f "tokens=* delims= " %%p in ("!PASSWORD!") do set "PASSWORD=%%p"
                :: 仅移除末尾的句点（而不是所有句点）
                if "!PASSWORD:~-1!"=="." set "PASSWORD=!PASSWORD:~0,-1!"
            ) else if "!KEY:~0,4!"=="下载地址" (
                set /a URL_COUNT+=1
                set "URL_!URL_COUNT!=!VALUE!"
                set "DOWNLOAD_URLS=!DOWNLOAD_URLS! !URL_COUNT!"
            )
        )
    )
)

:: 检查是否找到了密码
if "!PASSWORD!"=="" (
    echo 错误：配置文件中未找到有效的密码
    echo 请检查配置文件格式是否正确
    echo 配置文件内容示例：
    echo [DEFAULT]
    echo 密码=您的密码
    echo 下载地址1=URL1
    echo 下载地址2=URL2
    echo ...
    pause & exit /b 1
)
echo 密码已读取（长度: !PASSWORD:~0,5!*****）

:: 3. 下载所有配置的文件
echo 正在检查并下载所需文件...

:: 重置关键文件变量
set "ZIP_FILE="
set "DRIVER_FILE="
set "PY_FILE="
set "DEST="

for %%i in (%DOWNLOAD_URLS%) do (
    set "URL=!URL_%%i!"
    :: 从URL提取文件名
    for %%f in ("!URL!") do set "FILENAME=%%~nxf"

    set "TARGET_FILE=%DESKTOP%\!FILENAME!"

    if exist "!TARGET_FILE!" (
        echo !FILENAME! 已存在，跳过下载
    ) else (
        echo 正在下载 !FILENAME! ...
        powershell -NoP -Command "(New-Object Net.WebClient).DownloadFile('!URL!','!TARGET_FILE!')"
        if errorlevel 1 (echo !FILENAME! 下载失败 & pause & exit /b 1)
    )

    :: 设置关键文件的路径变量 - 修复了这里
    echo 正在检查文件: !FILENAME!
    if "!FILENAME:~-4!"==".zip" (
        echo 找到 ZIP 文件: !FILENAME!
        set "ZIP_FILE=!TARGET_FILE!"
        set "DEST=%DESKTOP%\!FILENAME:~0,-4!"
    )

    if "!FILENAME!"=="msedgedriver138.exe" (
        echo 找到 driver 文件: !FILENAME!
        set "DRIVER_FILE=!TARGET_FILE!"
    )

    if "!FILENAME:~-18!"=="python-3.13.5-amd64.exe" (
        echo 找到 Python 安装文件: !FILENAME!
        set "PY_FILE=!TARGET_FILE!"
    )
)

:: 检查是否找到了必要的文件
if not defined ZIP_FILE (
    echo 错误：未找到 ZIP 文件
    echo 已下载的文件列表:
    for %%i in (%DOWNLOAD_URLS%) do (
        for %%f in ("!URL_%%i!") do echo - %%~nxf
    )
    pause & exit /b 1
)
echo 找到 ZIP 文件: %ZIP_FILE%
if defined DEST echo 目标目录将为: %DEST%

:: 4. 解压文件（仅当目标目录不存在时）
if not exist "%DEST%" (
    echo 正在解压文件到 %DEST% ...
    "C:\Program Files\7-Zip\7z.exe" x "%ZIP_FILE%" -o"%DEST%" -p!PASSWORD! -y
    if errorlevel 1 (
        echo 解压失败，请检查密码是否正确
        echo 尝试使用的密码: !PASSWORD:~0,5!*****
        pause & exit /b 1
    )
) else (
    echo %DEST% 已存在，跳过解压
)

:: 5. 移动 driver（仅当目标目录存在时）
if exist "%DEST%" (
    if defined DRIVER_FILE (
        if exist "%DRIVER_FILE%" (
            echo 正在移动 msedgedriver138.exe 到 %DEST% ...
            move /y "%DRIVER_FILE%" "%DEST%\" >nul
            if errorlevel 1 (echo driver 移动失败 & pause & exit /b 1)
        ) else (
            echo 警告：msedgedriver138.exe 未找到，跳过移动
        )
    )
) else (
    echo 错误：解压目录 %DEST% 不存在，无法移动 driver
    pause & exit /b 1
)

:: 6. 安装 Python（仅当未安装时）
if not exist "%ProgramFiles%\Python313\python.exe" (
    if defined PY_FILE (
        if exist "%PY_FILE%" (
            echo 正在静默安装 Python ...
            "%PY_FILE%" /quiet InstallAllUsers=1 PrependPath=1
            if errorlevel 1 (echo Python 安装失败 & pause & exit /b 1)
            echo Python 安装完成
        ) else (
            echo 警告：Python 安装文件未找到，跳过安装
        )
    )
) else (
    echo Python 3.13.5 已安装（路径：%ProgramFiles%\Python313），跳过安装
)

:: 7. 设置 pip 源并安装依赖（仅当 Python 已安装时）
if exist "%ProgramFiles%\Python313\python.exe" (
    echo 正在设置 pip 源为腾讯云...
    "%ProgramFiles%\Python313\python.exe" -m pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple
    "%ProgramFiles%\Python313\python.exe" -m pip config set global.trusted-host mirrors.cloud.tencent.com

    echo 正在安装依赖（requirements.txt）...
    if exist "%DEST%\requirements.txt" (
        "%ProgramFiles%\Python313\python.exe" -m pip install -r "%DEST%\requirements.txt"
        if errorlevel 1 (echo 依赖安装失败 & pause & exit /b 1)
    ) else (
        echo 警告：未找到 requirements.txt，跳过依赖安装
    )
) else (
    echo 警告：Python 未安装，无法设置 pip 源和安装依赖
)

:: 8. 打开结果
if exist "%DEST%" explorer "%DEST%"
echo 全部完成！
pause