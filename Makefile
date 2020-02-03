.PHONY: run

zvmasm.bin: zvmasm.elf
	s390x-linux-gnu-objcopy -O binary "$<" "$@"

ipl.o: ipl.c
	s390x-linux-gnu-gcc -c "$<" -o "$@"

zvmasm.elf: ipl.S ipl.o main.c
	s390x-linux-gnu-gcc -nostdlib $^ \
		-static -Wl,-T link.ld \
		-o "$@"

run: zvmasm.bin
	qemu-system-s390x -kernel "$<" -m 16 -serial mon:stdio -display none -d in_asm,guest_errors
