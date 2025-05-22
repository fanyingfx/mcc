format ELF64 executable
segment readable executable
entry call_fun
fun:
	push rbp
	mov rbp,rsp
	mov eax,edi
	add eax,[rbp +24]
	mov rsp,rbp
	pop rbp
	ret

call_fun:
	mov rbp,rsp
	mov rdi,15
	push rdi
	sub rsp,8
	mov edi,1
	mov esi,2
	mov edx,3
	mov ecx,4
	mov r8d,5
	mov r9d,6
	push 8
	push 7
	call fun
	add rsp,24
	pop rdi

