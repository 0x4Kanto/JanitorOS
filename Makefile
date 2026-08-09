ASM := nasm
QEMU := qemu-system-i386

SRC := src

BOOT := boot.bin
KERNEL := kernel.bin
IMAGE := janitor.img

.PHONY: all run clean

all: $(IMAGE)

$(BOOT): $(SRC)/boot.asm
	$(ASM) -f bin $< -o $@

$(KERNEL): $(SRC)/kernel.asm
	$(ASM) -f bin $< -o $@

$(IMAGE): $(BOOT) $(KERNEL)
	cat $(BOOT) $(KERNEL) > $@
	truncate -s 1474560 $@

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
	$(QEMU) -drive format=raw,if=floppy,file=$(IMAGE)

clean:
	rm -f $(BOOT) $(KERNEL) $(IMAGE)
