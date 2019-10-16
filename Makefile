.SUFFIXES: # disable built-in rules
.SECONDARY: # don't delete intermediate files

# inspired by libtransistor-base makefile

# start llvm programs

# On MacOS, brew refuses to install clang5/llvm5 in a global place. As a result,
# they have to muck around with changing the path, which sucks.
# Let's make their lives easier by asking brew where LLVM_CONFIG is.
ifeq ($(shell uname -s),Darwin)
    ifeq ($(shell brew --prefix llvm),)
        $(error need llvm installed via brew)
    else
        LLVM_CONFIG := $(shell brew --prefix llvm)/bin/llvm-config
    endif
else
    LLVM_CONFIG := llvm-config$(LLVM_POSTFIX)
endif

LLVM_BINDIR := $(shell $(LLVM_CONFIG) --bindir)
ifeq ($(LLVM_BINDIR),)
  $(error llvm-config needs to be installed)
endif

LD := $(LLVM_BINDIR)/ld.lld
CC := $(LLVM_BINDIR)/clang
CXX := $(LLVM_BINDIR)/clang++
AS := $(LLVM_BINDIR)/llvm-mc
AR := $(LLVM_BINDIR)/llvm-ar
RANLIB := $(LLVM_BINDIR)/llvm-ranlib
# end llvm programs

VNC_PORT := ":0"

SOURCE_ROOT = .
SRC_DIR = $(SOURCE_ROOT)/src
BUILD_DIR := $(SOURCE_ROOT)/build
LIB_DIR = $(BUILD_DIR)/lib/
TARGET_TRIPLET = i386-unknown-none
LINK_SCRIPT = link.T

# For compiler-rt, we need some system header
SYS_INCLUDES := -isystem $(realpath $(SOURCE_ROOT))/include/
CC_FLAGS := -g -fno-builtin -fno-stack-protector -fno-rtti -nostdlib -nodefaultlibs -nostdlibinc $(SYS_INCLUDES)
CXX_FLAGS := $(CC_FLAGS) -std=c++17 -stdlib=libc++ -nodefaultlibs -nostdinc++
AR_FLAGS := rcs
AS_FLAGS := -g -arch=i386 -triple $(TARGET_TRIPLET)

LD_FLAGS :=	--eh-frame-hdr \
	--no-undefined \
	-T $(LINK_SCRIPT) \

# for compatiblity
CFLAGS := $(CC_FLAGS)
CXXFLAGS := $(CXX_FLAGS)

# Crystal
CRYSTAL = crystal
SHARDS = shards
CRFLAGS = --cross-compile --prelude=./prelude --target="$(TARGET_TRIPLET)" --error-trace --emit llvm-ir
SOURCES := $(shell find src lib -type f -name '*.cr')

# export
export LD
export CC
export CXX
export AS
export AR
export LD_FOR_TARGET = $(LD)
export CC_FOR_TARGET = $(CC)
export AS_FOR_TARGET = $(AS) -arch=i386
export AR_FOR_TARGET = $(AR)
export RANLIB_FOR_TARGET = $(RANLIB)
export CFLAGS_FOR_TARGET = $(CC_FLAGS) -Wno-unused-command-line-argument -Wno-error-implicit-function-declaration

NAME = farcry
all: $(NAME).iso #docs

# start compiler-rt definitions
LIB_COMPILER_RT_BUILTINS := $(BUILD_DIR)/compiler-rt/lib/libclang_rt.builtins-i386.a
include mk/compiler-rt.mk
# end compiler-rt definitions

OBJECTS = $(LIB_COMPILER_RT_BUILTINS) $(BUILD_DIR)/$(NAME).o $(BUILD_DIR)/crt0.o

$(BUILD_DIR)/$(NAME).o: lib $(SOURCES)
	mkdir -p $(@D)
	$(CRYSTAL) build src/main.cr -o $(BUILD_DIR)/$(NAME) $(CRFLAGS)

$(BUILD_DIR)/$(NAME).elf: $(OBJECTS)
	$(LD) $(LD_FLAGS) -o $@ $+

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S
	mkdir -p $(@D)
	$(CC) $(CC_FLAGS) -target $(TARGET_TRIPLET) -c -o $@ $<

clean: clean_compiler-rt
	rm -rf $(OBJECTS) main.ll $(BUILD_DIR)/$(NAME).elf docs isofiles/boot/farcry $(NAME).iso

docs: $(SOURCES)
	$(CRYSTAL) docs src/main_docs.cr

lib: shard.yml
	$(SHARDS) install

isofiles/boot/$(NAME): $(BUILD_DIR)/$(NAME).elf
	cp  $(BUILD_DIR)/$(NAME).elf isofiles/boot/$(NAME)

$(NAME).iso: isofiles/boot/$(NAME)
	mkisofs-rs external/grub/isofiles isofiles -o $(NAME).iso -b boot/grub/i386-pc/eltorito.img --no-emul-boot --boot-info-table --embedded-boot external/grub/embedded.img

qemu-debug: $(NAME).iso
	qemu-system-i386 -d cpu_reset -d int -serial stdio -machine q35 -no-reboot -boot d -cdrom $(NAME).iso -vnc ${VNC_PORT} -s -S

qemu: $(NAME).iso
	qemu-system-i386 -serial stdio -machine q35 -no-reboot -boot d -cdrom $(NAME).iso -vnc ${VNC_PORT}

.PHONY: clean all
