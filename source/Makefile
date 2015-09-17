# Makefile for rvtl
#     2010/02/28  Jun Mizutani


INSTALLDIR = /usr/bin/
#INSTALLDIR = /bin/

SOURCE = errno.inc fb.inc mman.inc rvtl.asm syscall.inc vtlfb.inc \
         ext.inc fblib.inc mt19937.inc signal.inc syserror.inc vtllib.inc


all : rvtl

rvtlm : ${SOURCE}
	nasm -f elf rvtl.asm -dNO_FB
	ld -s -melf_i386 -o rvtlm rvtl.o

rvtls : ${SOURCE}
	nasm -f elf rvtl.asm -dSMALL_VTL
	ld -s -melf_i386 -o rvtls rvtl.o

rvtl : ${SOURCE}
	nasm -f elf rvtl.asm
	ld -s -melf_i386 -o rvtl rvtl.o

debug : ${SOURCE}
	nasm -f elf rvtl.asm -dDEBUG
	ld -s -melf_i386 -o rvtl rvtl.o

install :
	cp rvtl ${INSTALLDIR}

uninstall :
	rm ${INSTALLDIR}rvtl

dist :
	rm *.o
	mv rvtl ..

clean :
	rm *.o rvtl
