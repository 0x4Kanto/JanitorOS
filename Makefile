ASM      := nasm
QEMU     := qemu-system-i386

SRC      := src
BUILD    := build

BOOT     := $(BUILD)/boot.bin
KERNEL   := $(BUILD)/kernel.bin
IMAGE    := $(BUILD)/janitor.img

KERNEL_SECTORS := 16
SECTOR_SIZE    := 512
MAX_KERNEL_SIZE := $(shell echo $$(($(KERNEL_SECTORS) * $(SECTOR_SIZE))))

KERNEL_SOURCES := \
	$(SRC)/kernel.asm \
	$(SRC)/console.asm \
	$(SRC)/input.asm \
	$(SRC)/commands.asm \
	$(SRC)/math.asm

.PHONY: all run clean check-size

all: $(IMAGE)

$(BUILD):
	mkdir -p $(BUILD)

$(BOOT): $(SRC)/boot.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

$(KERNEL): $(KERNEL_SOURCES) | $(BUILD)
	$(ASM) -f bin $(SRC)/kernel.asm -o $@
	@size=$$(wc -c < $@); \
	if [ $$size -gt $(MAX_KERNEL_SIZE) ]; then \
		echo "Error: kernel is $$size bytes."; \
		echo "Bootloader only loads $(MAX_KERNEL_SIZE) bytes."; \
		rm -f $@; \
		exit 1; \
	fi
	@echo "Kernel size: $$(wc -c < $@) bytes / $(MAX_KERNEL_SIZE) bytes"

$(IMAGE): $(BOOT) $(KERNEL)
	cat $(BOOT) $(KERNEL) > $@
	truncate -s 1474560 $@

check-size: $(KERNEL)
	@echo "Maximum kernel size: $(MAX_KERNEL_SIZE) bytes"
	@echo "Actual kernel size:  $$(wc -c < $(KERNEL)) bytes"

run: $(IMAGE)
	@command -v $(QEMU) >/dev/null 2>&1 || { \
		echo "Error: $(QEMU) is not installed."; \
		echo ""; \
		echo "Install QEMU and try again."; \
		echo "Examples:"; \
		echo "  Debian/Ubuntu: sudo apt install qemu-system-x86"; \
		echo "  Fedora:        sudo dnf install qemu-system-x86"; \
		echo "  Arch Linux:    sudo pacman -S qemu-desktop"; \
		exit 1; \
	}
	$(QEMU) \
		-drive format=raw,if=floppy,file=$(IMAGE)

clean:
	rm -rf $(BUILD)
