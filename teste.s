	.arch armv5te
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 18, 4
	.file	"teste.c"
	.text
	.align	2
	.global	_start
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, .L3
	mov	r1, #1000
	bl	add_alarm
	mov	r3, #0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L4:
	.align	2
.L3:
	.word	setMot0
	.size	_start, .-_start
	.align	2
	.global	setMot0
	.type	setMot0, %function
setMot0:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	mov	r3, #0
	strb	r3, [fp, #-8]
	mov	r3, #30
	strb	r3, [fp, #-7]
	mov	r3, #1
	strb	r3, [fp, #-12]
	mov	r3, #0
	strb	r3, [fp, #-11]
	sub	r2, fp, #8
	sub	r3, fp, #12
	mov	r0, r2
	mov	r1, r3
	bl	set_motors_speed
	sub	r3, fp, #16
	mov	r0, r3
	bl	get_time
	ldr	r3, [fp, #-16]
	add	r3, r3, #800
	ldr	r0, .L7
	mov	r1, r3
	bl	add_alarm
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L8:
	.align	2
.L7:
	.word	setMot1
	.size	setMot0, .-setMot0
	.align	2
	.global	setMot1
	.type	setMot1, %function
setMot1:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	mov	r3, #0
	strb	r3, [fp, #-8]
	mov	r3, #0
	strb	r3, [fp, #-7]
	mov	r3, #1
	strb	r3, [fp, #-12]
	mov	r3, #30
	strb	r3, [fp, #-11]
	sub	r2, fp, #8
	sub	r3, fp, #12
	mov	r0, r2
	mov	r1, r3
	bl	set_motors_speed
	sub	r3, fp, #16
	mov	r0, r3
	bl	get_time
	ldr	r3, [fp, #-16]
	add	r3, r3, #800
	ldr	r0, .L11
	mov	r1, r3
	bl	add_alarm
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L12:
	.align	2
.L11:
	.word	setMot0
	.size	setMot1, .-setMot1
	.align	2
	.global	setMot2
	.type	setMot2, %function
setMot2:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	mov	r3, #0
	strb	r3, [fp, #-8]
	mov	r3, #40
	strb	r3, [fp, #-7]
	mov	r3, #1
	strb	r3, [fp, #-12]
	mov	r3, #40
	strb	r3, [fp, #-11]
	sub	r2, fp, #8
	sub	r3, fp, #12
	mov	r0, r2
	mov	r1, r3
	bl	set_motors_speed
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	setMot2, .-setMot2
	.ident	"GCC: (GNU) 4.4.3"
	.section	.note.GNU-stack,"",%progbits
