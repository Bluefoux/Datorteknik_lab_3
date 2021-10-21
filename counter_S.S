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
	call	Place_GPIO_X_on
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
	movq 	$1, %rdi
	call	Place_GPIO_X_off
	movq 	$2, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_2 som output
	movq 	$2, %rdi
	call	Place_GPIO_X_off
	movq 	$3, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_3 som output
	movq 	$3, %rdi
	call	Place_GPIO_X_off
	movq 	$4, %rdi
	call 	Place_GPIO_X_as_output # Sätt GPIO_4 som output
	movq 	$4, %rdi
	call	Place_GPIO_X_off
	movq 	$0, %rdi
	movq 	%rdi, counter # Nollställ counter räknaren
	ret

.global GPIO_addr
GPIO_addr:
	pushq	%rbx
	movq 	$96, %rax
	salq 	$16, %rax # Vänsterskift 16 steg (åt vänster)
	pushq 	%rax
	movq	$65535, %rax
	andq	$4096, %rax
	pushq	%rax
	movq	$158, %rax
	notq	%rax
	andq	$255, %rax
	popq	%rbx
	orq	%rbx, %rax
	popq	%rbx
	orq	%rbx, %rax
	movq	%rax, GPIO
	popq	%rbx
	ret

.global Place_GPIO_X_as_input
Place_GPIO_X_as_input:
	pushq	%rdi
	movq	$3, %rax
	subq	%rdi, %rax # (3-GPIO_NR) = rax
	salq	$1, %rax # rax *2 # rax*2
	movq	$0, %rdx
	movq	$8, %rbx
	divq	%rbx # rax modulus 8 (rest in rdx)
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
	leaq	GPIO, %rbx
	popq	%rdi
	sarq	$3, %rdi # GPIO_NR >> 3 = GPIO_NR/2/2/2 = GPIO_NR/8
	addq	%rdi, %rbx
	orb	%al, (%rbx)
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
	leaq	GPIO, %rbx
	orb	%al, (%rbx)
	popq	%rbx
	popq	%rax
	popq	%rdi
	ret

.global Place_GPIO_X_on
Place_GPIO_X_on:
	decq	%rdi # GPIO_NR-1 = rdi
	salq	$3, %rdi # rdi << 3 = rdi*2*2*2 = rdi *8
	movq	$3, %rax
	salq	$4, %rax # 3 << 4 = rax
	incq	%rax # rax += 1
time_2_again_on:
	cmpq	$0, %rdi
	jle	finish_on
	salq	$1, %rax
	decq	%rdi
	jmp	time_2_again_on
finish_on:
	leaq	GPIO, %rbx
	addq	$3, %rbx
	orw	%ax, (%rbx)
	ret

.global Place_GPIO_X_off
Place_GPIO_X_off:
	decq	%rdi
	salq	$3, %rdi
	movq	$207, %rax
time_2_again_off: # rax << rdi
	cmpq	$0, %rdi
	jle	finish_off
	salq	$1, %rax
	decq	%rdi
	jmp	time_2_again_on
finish_off:
	negq	%rax
	leaq	GPIO, %rbx
	addq	$3, %rbx
	andw	%ax, (%rbx)
	ret
