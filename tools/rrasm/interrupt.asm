mov r0, 0x0100
mov sp, r0	; set up stack through `sp`
mov r0, interrupt_handler
mov iva, r0	; set up interrupt handler through `iva` control register

mov r0, 0x4321	; set r0 to something meaningful so we can check if it's preserved
dd 0xfefefefe	; invalid opcode, should trigger exception

mov r15, 0x1234	; signal stall in gtkwave
stall:
jmp stall	; stall

; todo: allow these symbol declarations to be inline with instructions like nasm?
interrupt_handler:
	push r0		; we will clobber r0
	push r1		; and r1
	mov r1, sp	; grab stack pointer into r1
	mov r0,  [r1 + 0x0002]	; interrupt address
	mov r14, [r1 + 0x0003]	; interrupt reason

	add r0, 2	; skip faulting instruction
	mov r1, retaddr	; put wound pc into retaddr
	mov [r1], r0

	pop r1
	pop r0
	db 0x14, 0x00	; exit handler
retaddr:
	dw 0x0000