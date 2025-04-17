format ELF64 executable
segment readable executable
entry _start
_start:
  call main
  mov  rdi,rax
  mov  rax,60
  syscall
main:
  push rbp
  mov  rbp, rsp
  sub rsp, 8
  mov dword [rbp -4], 2
  neg dword [rbp -4]
  mov r10d, dword [rbp -4]
  mov dword [rbp -8], r10d
  not dword [rbp -8]
  mov eax, dword [rbp -8]
  mov rsp, rbp
  pop rbp
  ret