///|
test {
  let content =
    #| int main(void){
    #|    return ~(-2);
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = @tacky.emit_tacky(ast,@utils.Counter::new())
  let asm = @backend.compile(tacky)
  let asm_str = emit(asm)
  inspect!(
    asm_str,
    content=
      #|format ELF64
      #|section ".text" executable
      #|public _start
      #|_start:
      #|  call main
      #|  mov rdi,rax
      #|  mov rax,60
      #|  syscall
      #|main:
      #|  push rbp
      #|  mov  rbp, rsp
      #|  sub rsp, 8
      #|  mov dword [rbp -4], 2
      #|  neg dword [rbp -4]
      #|  mov r10d, dword [rbp -4]
      #|  mov dword [rbp -8], r10d
      #|  not dword [rbp -8]
      #|  mov eax, dword [rbp -8]
      #|  mov rsp, rbp
      #|  pop rbp
      #|  ret
      #|  mov eax, 0
      #|  mov rsp, rbp
      #|  pop rbp
      #|  ret
      #|


    ,
  )
}
