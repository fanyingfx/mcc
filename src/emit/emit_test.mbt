///|
test {
  let content =
    #| int main(void){
    #|    return ~(-2);
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = @tacky.emit_tacky(validated_ast, counter)
  let asm = @backend.compile(tacky)
  let asm_str = emit(asm, symbol_table)
  inspect!(
    asm_str,
    content=
      #|format ELF64
      #|section ".text" executable
      #|
      #|public _start
      #|_start:
      #|  call main
      #|  mov rdi,rax
      #|  mov rax,60
      #|  syscall
      #|main:
      #|  push rbp
      #|  mov  rbp, rsp
      #|  sub rsp, 16
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
