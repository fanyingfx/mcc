///|
let start_main =
  #|format ELF64 executable
  #|segment readable executable
  #|entry _start
  #|_start:
  #|  call main
  #|  mov  rdi,rax
  #|  mov  rax,60
  #|  syscall

///|
pub fn emit(program : @asm.Program) -> String {
  let function_asm = emit_function(program.function_def)
  let asm = match program.function_def.name {
    "main" => "\{start_main}\n\{function_asm}"
    _ => function_asm
  }
  asm
}

///|
fn emit_function(function_def : @asm.FunctionDef) -> String {
  let label = function_def.name
  let instructions = function_def.instructions.map(fn(instruction) {
    "  " + emit_instruction(instruction)
  })
  $|\{label}:
  #|  push rbp
  #|  mov  rbp, rsp
  $|\{@string.concat(instructions)}
}

///|
fn emit_instruction(instr : @asm.Instruction) -> String {
  let instrction = match instr {
    Mov(dst~, src~) => "mov \{show_operand(dst)}, \{show_operand(src)}"
    Ret =>
      #|mov rsp, rbp
      #|  pop rbp
      #|  ret
  }
  instrction + "\n"
}

///|
fn show_operand(operand : @asm.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Register => "eax"
  }
}

///|
test {
  let content =
    #| int main(void){
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let asm = @asm.gen_program(ast)
  let asm_str = emit(asm)
  // println(asm_str)
  inspect!(
    asm_str,
    content=
      #|format ELF64 executable
      #|segment readable executable
      #|entry _start
      #|_start:
      #|  call main
      #|  mov  rdi,rax
      #|  mov  rax,60
      #|  syscall
      #|main:
      #|  push rbp
      #|  mov  rbp, rsp
      #|  mov eax, 3
      #|  mov rsp, rbp
      #|  pop rbp
      #|  ret
      #|
    ,
  )
}
