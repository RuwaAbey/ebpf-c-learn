# ============================================================
# eBPF C Lab - Root Makefile
# ============================================================

ROOT_DIR := $(CURDIR)
OUTPUT_DIR := $(ROOT_DIR)/.output

LIBBPF_SRC := $(ROOT_DIR)/third_party/libbpf/src
BPFTOOL_SRC := $(ROOT_DIR)/third_party/bpftool/src

LIBBPF_BUILD := $(OUTPUT_DIR)/libbpf
BPFTOOL_BUILD := $(OUTPUT_DIR)/bpftool

LIBBPF_LIB := $(OUTPUT_DIR)/lib/libbpf.a
BPFTOOL := $(BPFTOOL_BUILD)/bpftool

# Automatically discover example directories containing Makefiles
EXAMPLES := $(patsubst %/Makefile,%,$(wildcard examples/*/Makefile))

.PHONY: all dependencies examples clean distclean $(EXAMPLES)

all: examples

dependencies: $(LIBBPF_LIB) $(BPFTOOL)

# ------------------------------------------------------------
# Create directories
# ------------------------------------------------------------

$(OUTPUT_DIR) $(LIBBPF_BUILD) $(BPFTOOL_BUILD):
	mkdir -p $@

# ------------------------------------------------------------
# Build libbpf
# ------------------------------------------------------------

$(LIBBPF_LIB): | $(OUTPUT_DIR) $(LIBBPF_BUILD)
	$(MAKE) -C $(LIBBPF_SRC) \
	    BUILD_STATIC_ONLY=1 \
	    OBJDIR=$(LIBBPF_BUILD) \
	    DESTDIR=$(OUTPUT_DIR) \
	    INCLUDEDIR=/include \
	    LIBDIR=/lib \
	    install

# ------------------------------------------------------------
# Build bpftool
# ------------------------------------------------------------

$(BPFTOOL): $(LIBBPF_LIB) | $(BPFTOOL_BUILD)
	$(MAKE) -C $(BPFTOOL_SRC) \
	    OUTPUT=$(BPFTOOL_BUILD)/ \
	    LIBBPF_OUTPUT=$(LIBBPF_BUILD)/ \
	    LIBBPF_DESTDIR=$(OUTPUT_DIR)/

# ------------------------------------------------------------
# Build all examples
# ------------------------------------------------------------

examples: dependencies $(EXAMPLES)

$(EXAMPLES): dependencies
	$(MAKE) -C $@ ROOT_DIR=$(ROOT_DIR)

# ------------------------------------------------------------
# Clean
# ------------------------------------------------------------

clean:
	@for dir in $(EXAMPLES); do \
	    $(MAKE) -C $$dir clean ROOT_DIR=$(ROOT_DIR) || exit $$?; \
	done

distclean:
	rm -rf $(OUTPUT_DIR)
