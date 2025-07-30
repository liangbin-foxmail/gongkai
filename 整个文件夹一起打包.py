#!/usr/bin/env python3
"""
create_secure_zip.py
使用 pyzipper 创建 AES-256 加密 zip，加密文件名，跳过 .exe
"""
import os
import shutil
import pyzipper

# ---------------- 配置参数 ----------------
SKIP_EXT   = {'.exe'}
SOURCE_DIR = "github注册-通用"        # 上一级目录中的子目录
BASE_NAME  = "gitub_auto"
# ----------------------------------------

def get_password():
    """读取脚本同目录下的 密码.txt"""
    pwd_file = os.path.join(os.path.dirname(__file__), "密码.txt")
    if not os.path.isfile(pwd_file):
        raise FileNotFoundError("缺少密码文件：密码.txt")
    with open(pwd_file, encoding="utf-8") as f:
        return f.read().strip()

def collect_files(root_dir):
    """遍历 root_dir，返回 (绝对路径, 压缩包内相对路径) 列表，跳过 .exe"""
    all_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        rel_dir = os.path.relpath(dirpath, root_dir)
        for name in filenames:
            if os.path.splitext(name)[1].lower() in SKIP_EXT:
                continue
            abs_path = os.path.join(dirpath, name)
            arc_path = os.path.join(rel_dir, name) if rel_dir != "." else name
            all_files.append((abs_path, arc_path))
    return all_files

def next_zip_name(script_dir, base_name):
    """返回下一个可用的 zip 文件名，如 gitub_auto001.zip"""
    idx = 1
    while True:
        name = f"{base_name}{idx:03d}.zip"
        if not os.path.exists(os.path.join(script_dir, name)):
            return name
        idx += 1
import re

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    source_dir = os.path.abspath(os.path.join(script_dir, "..", SOURCE_DIR))

    if not os.path.isdir(source_dir):
        print(f"目录不存在：{source_dir}")
        return

    files_to_zip = collect_files(source_dir)
    if not files_to_zip:
        print("没有需要压缩的文件。")
        return

    pattern = re.compile(rf"^{BASE_NAME}(\d{{3}})\.zip$")

    # 1) 先计算下一个序号（目录里最大序号 +1，没有则从 1 开始）
    max_index = 0
    for name in os.listdir(script_dir):
        m = pattern.match(name)
        if m:
            max_index = max(max_index, int(m.group(1)))
    next_index = max_index + 1 if max_index else 1
    zip_name = f"{BASE_NAME}{next_index:03d}.zip"

    # 2) 删除所有“不等于 next_index”的旧包
    for name in os.listdir(script_dir):
        if pattern.match(name) and name != zip_name:
            os.remove(os.path.join(script_dir, name))
            print(f"已删除旧压缩包: {name}")

    # 3) 创建加密 zip
    zip_path = os.path.join(script_dir, zip_name)
    password = get_password()
    with pyzipper.AESZipFile(zip_path, 'w',
                             compression=pyzipper.ZIP_DEFLATED,
                             encryption=pyzipper.WZ_AES) as zf:
        zf.setpassword(password.encode())
        zf.setencryption(pyzipper.WZ_AES, nbits=256)
        for abs_path, arc_path in files_to_zip:
            zf.write(abs_path, arc_path)

    print(f"已生成加密 zip: {zip_path}")

    import A00上传所有文件到仓库foxmail_gongkai
    A00上传所有文件到仓库foxmail_gongkai.开始()
if __name__ == '__main__':
    main()