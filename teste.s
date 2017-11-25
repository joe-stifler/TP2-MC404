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
	mov	r0, #3
	mov	r1, #4000
	ldr	r2, .L3
	bl	register_proximity_callback
	mov	r0, #4
	mov	r1, #4000
	ldr	r2, .L3+4
	bl	register_proximity_callback
	bl	setMot2
	mov	r3, #0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L4:
	.align	2
.L3:
	.word	setMot0
	.word	setMot1
	.size	_start, .-_start
	.align	2
	.global	setMot0
	.type	setMot0, %function
setMot0:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	mov	r3, #0
	strb	r3, [fp, #-8]
	mov	r3, #0
	strb	r3, [fp, #-7]
	mov	r3, #1
	strb	r3, [fp, #-12]
	mov	r3, #63
	strb	r3, [fp, #-11]
	sub	r2, fp, #8
	sub	r3, fp, #12
	mov	r0, r2
	mov	r1, r3
	bl	set_motors_speed
.L6:
	mov	r0, #3
	bl	read_sonar
	mov	r3, r0
	mov	r2, r3
	ldr	r3, .L8
	cmp	r2, r3
	bls	.L6
	bl	setMot2
	mov	r0, #3
	mov	r1, #4000
	ldr	r2, .L8+4
	bl	register_proximity_callback
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L9:
	.align	2
.L8:
	.word	3999
	.word	setMot0
	.size	setMot0, .-setMot0
	.align	2
	.global	setMot1
	.type	setMot1, %function
setMot1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	mov	r3, #0
	strb	r3, [fp, #-8]
	mov	r3, #63
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
.L11:
	mov	r0, #4
	bl	read_sonar
	mov	r3, r0
	mov	r2, r3
	ldr	r3, .L13
	cmp	r2, r3
	bls	.L11
	bl	setMot2
	mov	r0, #4
	mov	r1, #4000
	ldr	r2, .L13+4
	bl	register_proximity_callback
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L14:
	.align	2
.L13:
	.word	3999
	.word	setMot1
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
	mov	r3, #63
	strb	r3, [fp, #-7]
	mov	r3, #1
	strb	r3, [fp, #-12]
	mov	r3, #63
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
