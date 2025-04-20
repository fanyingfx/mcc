///|
priv trait OpearandToString {
  str(Self) -> String
}

///|
impl OpearandToString for @backend.UnaryOp with str(self) {
  match self {
    Neg => "neg"
    Not => "not"
  }
}

///|
impl OpearandToString for @backend.BinaryOp with str(self) {
  match self {
    Sub => "sub"
    Add => "add"
    Mul => "imul"
  }
}

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
pub fn emit(program : @backend.Program) -> String {
  let function_asm = emit_function(program.function_def)
  let asm = match program.function_def.name {
    "main" => "\{start_main}\n\{function_asm}"
    _ => function_asm
  }
  asm
}

///|
fn emit_function(function_def : @backend.FunctionDef) -> String {
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
fn emit_instruction(instr : @backend.Instruction) -> String {
  let instrction = match instr {
    Mov(dst~, src~) => "mov \{show_operand(dst)}, \{show_operand(src)}"
    Ret =>
      #|mov rsp, rbp
      #|  pop rbp
      #|  ret
    Unary(op, operand) => "\{op.str()} \{show_operand(operand)}"
    AllocateStack(i) => "sub rsp, \{i}"
    Idiv(operand) => "idiv \{show_operand(operand)}"
    Binary(op, e1, e2) => "\{op.str()} \{show_operand(e1)}, \{show_operand(e2)}"
    Cdq => "cdq"
  }
  instrction + "\n"
}

///|
fn show_operand(operand : @backend.Operand) -> String {
  match operand {
    Imm(i) => i.to_string()
    Reg(AX) => "eax"
    Reg(R10) => "r10d"
    Stack(i) => "dword [rbp \{i}]"
    Reg(DX) => "edx"
    Reg(R11) => "r11d"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}
