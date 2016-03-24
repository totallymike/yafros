ARCH?=x86_64

QEMU?=qemu-system-$(ARCH)

AS=nasm
LD=$(ARCH)-pc-elf-ld
NASMARGS=-f elf64 -g

default: run

build: build/os.iso

run: build/os.iso
	$(QEMU) -cdrom build/os.iso

debug: build/os.iso
	$(QEMU) -s -S -cdrom build/os.iso

build/os.iso: build/kernel.bin grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot/
	grub-mkrescue -o build/os.iso build/isofiles

build/multiboot_header.o: multiboot_header.asm
	mkdir -p build
	$(AS) $(NASMARGS) multiboot_header.asm -o build/multiboot_header.o

build/boot.o: boot.asm
	mkdir -p build
	$(AS) $(NASMARGS) boot.asm -o build/boot.o

build/error.o: error.asm
	mkdir -p build
	$(AS) $(NASMARGS) error.asm -o build/error.o

build/long_mode.o: long_mode.asm
	mkdir -p build
	$(AS) $(NASMARGS) long_mode.asm -o build/long_mode.o

build/long_mode_start.o: long_mode_start.asm
	mkdir -p build
	$(AS) $(NASMARGS) long_mode_start.asm -o build/long_mode_start.o

build/kernel.bin: build/multiboot_header.o build/boot.o build/error.o build/long_mode_start.o build/long_mode.o linker.ld
	$(LD) -n -o build/kernel.bin -T linker.ld build/multiboot_header.o build/error.o build/long_mode_start.o build/long_mode.o build/boot.o

.PHONY: clean
clean:
	rm -rf build
