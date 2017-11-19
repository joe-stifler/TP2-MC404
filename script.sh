#!/bin/bash
arm-eabi-gcc teste.c -S -o teste.s
arm-eabi-as teste.s -o teste.o
arm-eabi-as api_robot2.s -o api_robot2.o

arm-eabi-ld teste.o api_robot2.o -o program -Ttext=0x77812000 -Tdata=0x77813000

arm-eabi-as -g soul.s -o soul.o
arm-eabi-ld soul.o -o soul -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0

mksd.sh --so soul --user program

rm *.o
