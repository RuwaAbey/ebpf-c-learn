# ============================================================
# Example 01 - Hello World
# ============================================================

CLANG := clang
CC := gcc

# Repository root
ROOT_DIR ?= $(abspath ../..)

# Build directories
OUTPUT_DIR := $(ROOT_DIR)/.output
BUILD_DIR := $(OUTPUT_DIR)/examples/01-hello-world

# Shared dependencies
LIBBPF_INCLUDE := $(OUTPUT_DIR)/include
LIBBPF_LIB := $(OUTPUT_DIR)/lib/libbpf.a
BPFTOOL := $(OUTPUT_DIR)/bpftool/bpftool

# Source files
BPF_SRC := minimal.bpf.c
USER_SRC := minimal.c

# Generated files
BPF_OBJ := $(BUILD_DIR)/minimal.bpf.o
BPF_SKEL := $(BUILD_DIR)/minimal.skel.h
USER_BIN := $(BUILD_DIR)/minimal

# Compiler flags
MULTIARCH := $(shell $(CC) -dumpmachine)

BPF_CFLAGS := -g -O2 -target bpf \
              -D__TARGET_ARCH_x86 \
              -I/usr/include/$(MULTIARCH) \
              -I$(LIBBPF_INCLUDE)

USER_CFLAGS := -g -O2 -Wall \
               -I$(BUILD_DIR) \
               -I$(LIBBPF_INCLUDE)

.PHONY: all run clean

all: $(USER_BIN)

# ------------------------------------------------------------
# Create build directory
# ------------------------------------------------------------

$(BUILD_DIR):
	mkdir -p $@

# ------------------------------------------------------------
# Compile eBPF program
# ------------------------------------------------------------

$(BPF_OBJ): $(BPF_SRC) $(LIBBPF_LIB) | $(BUILD_DIR)
	$(CLANG) $(BPF_CFLAGS) \
	    -c $< \
	    -o $@

# ------------------------------------------------------------
# Generate skeleton
# ------------------------------------------------------------

$(BPF_SKEL): $(BPF_OBJ) $(BPFTOOL)
	$(BPFTOOL) gen skeleton $(BPF_OBJ) > $@

# ------------------------------------------------------------
# Compile userspace application
# ------------------------------------------------------------

$(USER_BIN): $(USER_SRC) $(BPF_SKEL) $(LIBBPF_LIB)
	$(CC) $(USER_CFLAGS) \
	    $(USER_SRC) \
	    $(LIBBPF_LIB) \
	    -lelf -lz \
	    -o $@

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------

run: $(USER_BIN)
	sudo $(USER_BIN)

# ------------------------------------------------------------
# Clean
# ------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)
