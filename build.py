import os
import zipfile
from datetime import datetime
import shutil

SRC_DIR = "src"
BUILDS_DIR = "builds"
LATEST_DIR = os.path.join(BUILDS_DIR, "latest")
PREVIOUS_DIR = os.path.join(BUILDS_DIR, "previous")


def ensure_dirs():
    os.makedirs(LATEST_DIR, exist_ok=True)
    os.makedirs(PREVIOUS_DIR, exist_ok=True)


def move_old_builds():
    for file in os.listdir(LATEST_DIR):
        if file.endswith(".pk3"):
            src = os.path.join(LATEST_DIR, file)
            dst = os.path.join(PREVIOUS_DIR, file)
            shutil.move(src, dst)


def zip_folder(folder_path, output_zip):
    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(folder_path):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, folder_path)
                zipf.write(full_path, rel_path)


def main():
    ensure_dirs()
    move_old_builds()

    timestamp = datetime.now().strftime("%Y-%m-%d---%H-%M-%S")
    build_name = f"FangsHeistRecode---{timestamp}.pk3"
    output_path = os.path.join(LATEST_DIR, build_name)

    zip_folder(SRC_DIR, output_path)

if __name__ == "__main__":
    main()
