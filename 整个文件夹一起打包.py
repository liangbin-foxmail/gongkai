#!/usr/bin/env python3
"""
create_secure_zip.py
使用 pyzipper 创建 AES-256 加密 zip，加密文件名，跳过 .exe
"""
import os
import shutil
import pyzipper
import re
from configparser import ConfigParser   # ← 新增

# ---------------- 配置参数 ----------------
SKIP_EXT   = {'.exe'}
SOURCE_DIR = "github注册-通用"
BASE_NAME  = "gitub_auto"
CONFIG_FILE = "../qinglong_foxmail_qinglong/配置文件.ini"  # ← 新增
# ----------------------------------------

def get_password():
    """从配置文件.ini 读取 [DEFAULT] 节下的 '密码' 字段"""
    cfg_path = os.path.join(os.path.dirname(__file__), CONFIG_FILE)
    if not os.path.isfile(cfg_path):
        raise FileNotFoundError(f"缺少配置文件：{CONFIG_FILE}")

    cfg = ConfigParser()
    cfg.read(cfg_path, encoding="utf-8")
    pwd = cfg["DEFAULT"].get("密码")
    if not pwd:
        raise ValueError(f"{CONFIG_FILE} 中缺少 '密码' 字段")
    return pwd.strip()

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

    # 1) 先计算下一个序号
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
    password = get_password()               # ← 现在读配置文件
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