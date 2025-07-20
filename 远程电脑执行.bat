@echo off
REM 下载ZIP文件（使用PowerShell）
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://github.com/liangbin-foxmail/gongkai/raw/main/dist.zip', 'dist.zip')"

REM 检查下载是否成功
if not exist "dist.zip" (
    echo 下载失败，请检查网络连接！
    pause
    exit /b 1
)

REM 解压带密码的ZIP到当前目录（需7-Zip已安装，路径正确）
"C:\Program Files\7-Zip\7z.exe" x -pAa123456 -y "dist.zip" -o"%CD%"

REM 检查解压是否成功（直接检查当前目录下的目标文件）
if not exist "msedgedriver.exe" (
    echo 解压失败或文件不存在！
    pause
    exit /b 1
)

REM 启动目标程序（当前目录下的文件）
echo 正在启动github自动创建账号-seleium.exe...
start "" "github-autocreat-seleium.exe"

echo 操作完成！
pause