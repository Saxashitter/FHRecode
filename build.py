import os
import zipfile
from datetime import datetime
import shutil
import hashlib
import sys

use_pto = "-pto" in sys.argv

SRC_DIR = "src"
MUSIC_DIR = os.path.join(SRC_DIR, "Music")

BUILDS_DIR = "builds"
LATEST_DIR = os.path.join(BUILDS_DIR, "latest")
PREVIOUS_DIR = os.path.join(BUILDS_DIR, "previous")

MUSIC_HASH_FILE = os.path.join(BUILDS_DIR, "music.hash")

if use_pto:
	LATEST_DIR = os.path.join(BUILDS_DIR, "pto")
	PREVIOUS_DIR = os.path.join(BUILDS_DIR, "pto-prev")
	MUSIC_HASH_FILE = os.path.join(BUILDS_DIR, "pto-music.hash")

# =====================
# Utils
# =====================

def ensure_dirs():
	os.makedirs(LATEST_DIR, exist_ok=True)
	os.makedirs(PREVIOUS_DIR, exist_ok=True)

def move_old_builds():
	for file in os.listdir(LATEST_DIR):
		if file.endswith(".pk3"):
			shutil.move(
				os.path.join(LATEST_DIR, file),
				os.path.join(PREVIOUS_DIR, file)
			)

def zip_folder(folder_path, output_zip, exclude=None):
	exclude = exclude or set()

	with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zipf:
		for root, _, files in os.walk(folder_path):
			for file in files:
				full_path = os.path.join(root, file)

				if any(full_path.startswith(e) for e in exclude):
					continue

				rel_path = os.path.relpath(full_path, folder_path)
				zipf.write(full_path, rel_path)

# =====================
# Hashing
# =====================

def hash_music_folder():
	hasher = hashlib.sha256()

	if not os.path.exists(MUSIC_DIR):
		return None

	for root, _, files in os.walk(MUSIC_DIR):
		for file in sorted(files):
			full_path = os.path.join(root, file)
			rel_path = os.path.relpath(full_path, MUSIC_DIR)

			hasher.update(rel_path.encode())

			with open(full_path, "rb") as f:
				hasher.update(f.read())

	return hasher.hexdigest()

def load_previous_music_hash():
	if not os.path.exists(MUSIC_HASH_FILE):
		return None
	with open(MUSIC_HASH_FILE, "r") as f:
		return f.read().strip()

def save_music_hash(hash_value):
	with open(MUSIC_HASH_FILE, "w") as f:
		f.write(hash_value)

# =====================
# Music PK3
# =====================

def build_music_pk3(output_zip):
	with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zipf:
		for root, _, files in os.walk(MUSIC_DIR):
			for file in files:
				full_path = os.path.join(root, file)
				rel_path = os.path.relpath(full_path, SRC_DIR)
				zipf.write(full_path, rel_path)

		init_lua = """\
-- Auto-generated init.lua
rawset(_G, "FH_PTO_BUILD", true)
"""
		zipf.writestr("init.lua", init_lua)

# =====================
# Main
# =====================

timestamp = datetime.now().strftime("%Y-%m-%d---%H-%M-%S")

main_pk3 = f"FangsHeistRecode---{timestamp}.pk3"
main_output = os.path.join(LATEST_DIR, main_pk3)

ensure_dirs()
move_old_builds()

if use_pto:
	# Main PK3 without music
	zip_folder(
		SRC_DIR,
		main_output,
		exclude={MUSIC_DIR}
	)

	# Hash check
	new_hash = hash_music_folder()
	old_hash = load_previous_music_hash()

	if new_hash != old_hash:
		music_pk3 = f"FangsHeistRecode-Music---{timestamp}.pk3"
		music_output = os.path.join(BUILDS_DIR, music_pk3)

		build_music_pk3(music_output)
		save_music_hash(new_hash)

else:
	# Normal single PK3 build
	zip_folder(SRC_DIR, main_output)

print(main_output)
