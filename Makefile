.RECIPEPREFIX := >

CXX := g++
LD  := ld

CXXFLAGS := -std=gnu++20 -O2 -g -Wall -Wextra -I src \
  -ffreestanding -fno-exceptions -fno-rtti \
  -fno-use-cxa-atexit -fno-threadsafe-statics \
  -fno-stack-protector -fno-stack-check -fno-PIC -fno-pie \
  -ffunction-sections -fdata-sections \
  -m64 -march=x86-64 -mno-80387 -mno-mmx -mno-sse -mno-sse2 \
  -mno-red-zone -mcmodel=kernel

LDFLAGS := -m elf_x86_64 -nostdlib -static -no-pie \
  -z max-page-size=0x1000 -z noexecstack --gc-sections -T linker.lds

SRC := $(wildcard src/*.cpp)
OBJ := $(patsubst src/%.cpp,obj/%.o,$(SRC))

all: image.iso

obj/%.o: src/%.cpp
> mkdir -p obj
> $(CXX) $(CXXFLAGS) -c $< -o $@

bin/myos: $(OBJ) linker.lds
> mkdir -p bin
> $(LD) $(LDFLAGS) $(OBJ) -o $@

limine-binary:
> curl -fL -o limine-binary.tar.gz https://github.com/Limine-Bootloader/Limine/releases/latest/download/limine-binary.tar.gz
> gunzip < limine-binary.tar.gz | tar -xf -
> make -C limine-binary

image.iso: bin/myos limine.conf | limine-binary
> rm -rf iso_root
> mkdir -p iso_root/boot/limine iso_root/EFI/BOOT
> cp bin/myos iso_root/boot/
> cp limine.conf limine-binary/limine-bios.sys limine-binary/limine-bios-cd.bin limine-binary/limine-uefi-cd.bin iso_root/boot/limine/
> cp limine-binary/BOOTX64.EFI limine-binary/BOOTIA32.EFI iso_root/EFI/BOOT/
> xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
    -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    iso_root -o image.iso
> ./limine-binary/limine bios-install image.iso

run: image.iso
> qemu-system-x86_64 -M q35 -m 256M -cdrom image.iso -boot d -serial mon:stdio -display none

clean:
> rm -rf bin obj iso_root image.iso

.PHONY: all run clean

stop:
> pkill qemu || true
