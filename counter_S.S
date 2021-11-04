	.data
counter:	.quad 0
GPIO:		.quad 0
	.text
	.global setup
	.global interrupt

interrupt:
	pushq	%rdi # save registers
	pushq	%rax
	pushq	%rbx
	
	call	incr_counter
	movq	$1, %rbx
	movq	$0, %rdi
loop_again:
	movq	counter, %rax
	andq	%rbx, %rax
	je	L1
	pushq	%rdi
	pushq	%r12
	movq	%rdi, %r12
	movq	$6, %rdi
	subq	%r12, %rdi
	call	Place_GPIO_X_on
	popq	%r12
	popq	%rdi
	salq	$1, %rbx
	incq	%rdi
	cmpq	$4, %rdi
	je	finish_interupt
	jmp	loop_again
L1:
	call	Place_GPIO_X_off
	salq	$1, %rbx
	incq	%rdi
	cmpq	$4, %rdi
	je	finish_interupt
	jmp	loop_again
finish_interupt:
	popq	%rbx # restore registers
	popq	%rax
	popq	%rdi 
	ret
incr_counter:
	pushq	%rdi
	movq	counter, %rax
	incq	%rax
	andq	$15, %rax
	movq	%rax, counter
	popq	%rdi
	ret

setup:
	call	GPIO_addr # beräkna gpio adressen
	movq 	$0, %rdi
	call 	Place_GPIO_X_as_input # Sätt GPIO_0 som input
	movq 	$1, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_1 som output
	movq 	$2, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_2 som output
	movq 	$3, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_3 som output
	movq 	$4, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_4 som output
	movl 	$0, %edi
	movl 	%edi, counter # Nollställ counter räknaren
	ret

.global GPIO_addr
GPIO_addr:
	pushq	%rbx
	movq 	$0x60, %rax
	salq 	$16, %rax # Vänsterskift 16 steg (åt vänster)
	pushq 	%rax
	movq	$0xFFFF, %rax
	andq	$0x1000, %rax
	pushq	%rax
	movq	$0x9E, %rax
	notq	%rax
	andq	$0xFF, %rax
	popq	%rbx
	orq	%rbx, %rax
	popq	%rbx
	orq	%rbx, %rax
	movl	%eax, %ecx
	movl	%ecx, GPIO
	popq	%rbx
	ret

.global Place_GPIO_X_as_input
Place_GPIO_X_as_input:
	pushq	%rdi
	movq	$3, %rax
	subq	%rdi, %rax # (3-GPIO_NR) = rax
	movq	$2, %rcx
	imulq	%rcx
	#salq	$1, %rax # rax *2 # rax*2
	movq	$8, %rbx
	idivq	%rbx # rax modulus 8 (rest in rdx)
	addq	$8, %rdx # rax+8
	movq	%rdx, %rbx
	movq	$3, %rax
time_2_again_input: # utför (rax << 1) rbx antal gånger
	cmpq	$0, %rbx
	jle	finish_input
	salq	$1, %rax # rax << 1
	decq	%rbx
	jmp	time_2_again_input
finish_input:
	pushq	%rax
	leal	GPIO, %ebx
	movq	%rdi, %rax
	movq	$0, %rdx
	movq	$8, %rcx
	divq	%rcx
	addl	%eax, %ebx
	popq	%rax
	movl	(%ebx), %r12d
	orw	%ax, (%r12d)
	popq	%rdi
	ret

.global Place_GPIO_X_as_output
Place_GPIO_X_as_output:
	pushq	%rdi
	pushq	%rax
	pushq	%rbx
	movq	$4, %rax
	subq	%rdi, %rax
	salq	$1, %rax
	movq	$2, %rdi
	salq	$6, %rdi
time_2_again_output:
	cmpq	$0, %rax
	jle	finish_output
	salq	$1, %rdi
	decq	%rax
	jmp	time_2_again_output
finish_output:
	leal	GPIO, %ebx
	movl	(%ebx), %ecx
	orw	%di, (%ecx)
	popq	%rbx
	popq	%rax
	popq	%rdi
	ret

.global Place_GPIO_X_on
Place_GPIO_X_on:
	decq	%rdi # GPIO_NR-1 = rdi
	salq	$3, %rdi # rdi << 3 = rdi*2*2*2 = rdi *8
	movq	$0x3, %rax
	salq	$4, %rax # 3 << 4 = rax
	incq	%rax # rax += 1
time_2_again_on:
	cmpq	$0, %rdi
	jle	finish_on
	salq	$1, %rax
	decq	%rdi
	jmp	time_2_again_on
finish_on:
	leal	GPIO, %ebx
	pushq	%rbx
	movl	(%ebx), %r12d
	pushq	%r12
	addl	$3, %r12d
	orl	%eax, (%r12d)
	popq	%r12
	popq	%rbx
	ret

.global Place_GPIO_X_off
Place_GPIO_X_off:
	pushq	%rdi
	pushq	%rax
	pushq	%rbx
	pushq	%rcx
	decq	%rdi
	salq	$3, %rdi
	movq	$0xCF, %rax
time_2_again_off: # rax << rdi
	cmpq	$0, %rdi
	jle	finish_off
	salq	$1, %rax
	decq	%rdi
	jmp	time_2_again_off
finish_off:
	notq	%rax
	leal	GPIO, %ebx
	pushq	%rbx
	movl	(%ebx), %r12d
	pushq	%r12
	addl	$3, %r12d
	andl	%eax, (%r12d)	
	popq	%r12
	popq	%rbx
	popq	%rcx
	popq	%rbx
	popq	%rax
	popq	%rdi
	ret
