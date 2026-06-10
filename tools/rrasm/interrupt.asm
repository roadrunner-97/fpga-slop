xor r0, r0
mov r0, interrupt_handler
mov iva, r0	; set up interrupt handler through `iva` control register

mov r0, 0x4321	; set r0 to something meaningful so we can check if it's preserved
dd 0xfefefefe	; invalid opcode, should trigger exception

mov r15, 0x1234	; signal stall in gtkwave
stall:
jmp stall	; stall

; todo: allow these symbol declarations to be inline with instructions like nasm?
r0_save:
	dd 0x00000000	; no stack, must store temporarily copy in RAM, also aligned=
interrupt_handler:
	mov r7, r0_save	; use unnused r7 as scratch register ! FIX THIS, THIS IS TERRIBLE !
	mov [r7], r0	; save old r0
	mov r14, ivr	; interrupt reason
	mov r0, ivo	; interrupt address

	add r0, 2	; skip faulting instruction
	mov r7, retaddr
	mov [r7], r0

	mov r7, r0_save
	mov r0, [r7]
	db 0x14, 0x00	; jmpabs retaddr
retaddr:
	dw 0x0000