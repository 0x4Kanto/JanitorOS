CC=gcc
LD=ld
ASM=nasm

SRC=src

CFLAGS=-m16 \
       -ffreestanding \
       -fno-pie \
       -fno-pic \
       -fno-stack-protector \
       -fno-asynchronous-unwind-tables \
       -c

all: janitor.img

boot.bin: $(SRC)/boot.asm
	$(ASM) -f bin $< -o $@

entry.o: $(SRC)/entry.asm
	$(ASM) -f elf32 $< -o $@

kernel.o: $(SRC)/kernel.c
	$(CC) -m16 -ffreestanding \
	      -fno-pie \
	      -fno-pic \
	      -fno-stack-protector \
	      -fno-asynchronous-unwind-tables \
	      -fno-unwind-tables \
	      -O0 -g \
	      -c $< -o $@

kernel.bin: entry.o kernel.o
	$(LD) -m elf_i386 \
	      -T $(SRC)/linker.ld \
	      --oformat binary \
	      entry.o kernel.o \
	      -o $@

janitor.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > $@
	truncate -s 1474560 $@

run: janitor.img
	qemu-system-i386 -drive format=raw,if=floppy,file=$<

clean:
	rm -f *.o *.bin janitor.img
