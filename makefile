# ----- Tools -----
PYTHON := python

# ----- Project paths (absolute) -----
PROJECT_DIR := $(abspath .)
BUILD_SCRIPT := $(PROJECT_DIR)/build.py

# ----- SRB2 paths (absolute) -----
SRB2_DIR := D:/stuff/SRB2-v2215-Full
SRB2_EXE := $(SRB2_DIR)/srb2win.exe

# ----- Run python and capture absolute build filename -----
BUILD := $(shell $(PYTHON) "$(BUILD_SCRIPT)")

.PHONY: build run dual clean

build:
	@echo Build output: $(BUILD)

run: build
	cd "$(SRB2_DIR)" && "$(SRB2_EXE)" -file "$(BUILD)" -windowed -console -server -gametype 8

dual: build
	cmd /c "cd /d $(SRB2_DIR) && start "" $(SRB2_EXE) -file "$(BUILD)" -windowed -console -server -gametype 8"
	cmd /c "cd /d $(SRB2_DIR) && start "" $(SRB2_EXE) -file "$(BUILD)" -windowed -console -connect localhost"

test: build
	cd "$(SRB2_DIR)" && "$(SRB2_EXE)" -file "$(BUILD)" -windowed -console -server -gametype 8 -warp Z1