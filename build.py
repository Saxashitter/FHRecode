import os
import zipfile
from datetime import datetime

def count_items(path):
    return len(os.listdir(path))

def zip_folder(folder_path, output_zip):
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(folder_path):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, folder_path)
                zipf.write(full_path, rel_path)

# Safe, sortable timestamp
timestamp = datetime.now().strftime("%Y-%m-%d---%H-%M-%S")

name = f"builds/FangsHeistRecode---{timestamp}.pk3"

zip_folder("src", name)
print(name)
