# ============================================================
# eBPF C Lab - Build System
# ============================================================

# Compilers
CLANG := clang
CC := gcc

# Directories
ROOT_DIR := $(CURDIR)
OUTPUT_DIR := $(ROOT_DIR)/.output

LIBBPF_SRC := $(ROOT_DIR)/third_party/libbpf/src
BPFTOOL_SRC := $(ROOT_DIR)/third_party/bpftool/src

LIBBPF_BUILD := $(OUTPUT_DIR)/libbpf
BPFTOOL_BUILD := $(OUTPUT_DIR)/bpftool

LIBBPF_INCLUDE := $(OUTPUT_DIR)/include
LIBBPF_LIB := $(OUTPUT_DIR)/lib/libbpf.a

BPFTOOL := $(BPFTOOL_BUILD)/bpftool

# Example directories
EXAMPLE_DIR := examples/01-hello-world
EXAMPLE_BUILD := $(OUTPUT_DIR)/01-hello-world

# Source files
BPF_SRC := $(EXAMPLE_DIR)/minimal.bpf.c
USER_SRC := $(EXAMPLE_DIR)/minimal.c

# Generated files
BPF_OBJ := $(EXAMPLE_BUILD)/minimal.bpf.o
BPF_SKEL := $(EXAMPLE_BUILD)/minimal.skel.h
USER_BIN := $(EXAMPLE_BUILD)/minimal

# Compiler flags (x86-64 Ubuntu)
MULTIARCH := $(shell $(CC) -dumpmachine)

BPF_CFLAGS := -g -O2 -target bpf \
              -D__TARGET_ARCH_x86 \
              -I/usr/include/$(MULTIARCH) \
              -I$(LIBBPF_INCLUDE)

USER_CFLAGS := -g -O2 -Wall \
               -I$(EXAMPLE_BUILD) \
               -I$(LIBBPF_INCLUDE)

# ============================================================
# Main targets
# ============================================================

.PHONY: all dependencies run clean distclean

all: $(USER_BIN)

dependencies: $(LIBBPF_LIB) $(BPFTOOL)

# ============================================================
# Create directories
# ============================================================

$(OUTPUT_DIR):
	mkdir -p $@

$(EXAMPLE_BUILD):
	mkdir -p $@

$(LIBBPF_BUILD):
	mkdir -p $@

$(BPFTOOL_BUILD):
	mkdir -p $@

# ============================================================
# Build libbpf
# ============================================================

$(LIBBPF_LIB): | $(OUTPUT_DIR) $(LIBBPF_BUILD)
	$(MAKE) -C $(LIBBPF_SRC) \
	    BUILD_STATIC_ONLY=1 \
	    OBJDIR=$(LIBBPF_BUILD) \
	    DESTDIR=$(OUTPUT_DIR) \
	    INCLUDEDIR=/include \
	    LIBDIR=/lib \
	    install

# ============================================================
# Build bpftool
# ============================================================

$(BPFTOOL): $(LIBBPF_LIB) | $(BPFTOOL_BUILD)
	$(MAKE) -C $(BPFTOOL_SRC) \
	    OUTPUT=$(BPFTOOL_BUILD)/ \
	    LIBBPF_OUTPUT=$(LIBBPF_BUILD)/ \
	    LIBBPF_DESTDIR=$(OUTPUT_DIR)/

# ============================================================
# Compile kernel-side eBPF program
# ============================================================

$(BPF_OBJ): $(BPF_SRC) $(LIBBPF_LIB) | $(EXAMPLE_BUILD)
	$(CLANG) $(BPF_CFLAGS) \
	    -c $< \
	    -o $@

# ============================================================
# Generate BPF skeleton
# ============================================================

$(BPF_SKEL): $(BPF_OBJ) $(BPFTOOL)
	$(BPFTOOL) gen skeleton $(BPF_OBJ) > $@

# ============================================================
# Compile userspace application
# ============================================================

$(USER_BIN): $(USER_SRC) $(BPF_SKEL) $(LIBBPF_LIB)
	$(CC) $(USER_CFLAGS) \
	    $(USER_SRC) \
	    $(LIBBPF_LIB) \
	    -lelf -lz \
	    -o $@

# ============================================================
# Run
# ============================================================

run: $(USER_BIN)
	sudo $(USER_BIN)

# ============================================================
# Clean
# ============================================================

clean:
	rm -rf $(EXAMPLE_BUILD)

distclean:
	rm -rf $(OUTPUT_DIR)
