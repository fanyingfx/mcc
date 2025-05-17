///|
priv trait ShowOp {
  str(Self) -> String
}

///|
priv trait ShowOperand {
  byte(Self) -> String
  dword(Self) -> String
}

///|
impl ShowOp for @backend.UnaryOp with str(self) {
  match self {
    Neg => "neg"
    Not => "not"
  }
}


///|
impl ShowOp for @backend.BinaryOp with str(self) {
  match self {
    Sub => "sub"
    Add => "add"
    Mul => "imul"
  }
}

let obj_header =
  #|format ELF64
  #|section ".text" executable
  #|

///|
let start_func =
  #|public _start
  #|_start:
  #|  call main
  #|  mov rdi,rax
  #|  mov rax,60
  #|  syscall
  #|

///|
pub fn emit(program : @backend.Program) -> String {
  let function_asm = program.function_defs.map(emit_function).join("\n")
  obj_header+start_func+function_asm
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
    Mov(dst~, src~) => "mov \{dst.dword()}, \{src.dword()}"
    Ret =>
      #|mov rsp, rbp
      #|  pop rbp
      #|  ret
    Unary(op, operand) => "\{op.str()} \{operand.dword()}"
    AllocateStack(i) => "sub rsp, \{i}"
    Idiv(operand) => "idiv \{operand.dword()}"
    Binary(op, e1, e2) => "\{op.str()} \{e1.dword()}, \{e2.dword()}"
    Cdq => "cdq"
    Jmp(label) => "jmp .L\{label}"
    Cmp(operand1, operand2) => "cmp \{operand1.dword()}, \{operand2.dword()}"
    JmpCC(cond_code, label) => "j\{convert_cond(cond_code)} .L\{label}"
    SetCC(cond_code, operand) =>
      "set\{convert_cond(cond_code)} \{operand.byte()}"
    Label(label) => ".L\{label}:"
  }
  instrction + "\n"
}

///|
fn convert_cond(cond_code : @backend.CondCode) -> String {
  match cond_code {
    L => "l"
    GE => "ge"
    G => "g"
    NE => "ne"
    E => "e"
    LE => "le"
  }
}

///|
impl ShowOperand for @backend.Operand with dword(self) {
  match self {
    Imm(i) => i.to_string()
    Reg(AX) => "eax"
    Reg(R10) => "r10d"
    Stack(i) => "dword [rbp \{i}]"
    Reg(DX) => "edx"
    Reg(R11) => "r11d"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}

///|
impl ShowOperand for @backend.Operand with byte(self) {
  match self {
    Imm(i) => i.to_string()
    Reg(AX) => "al"
    Reg(DX) => "dl"
    Reg(R10) => "r10b"
    Stack(i) => "byte [rbp \{i}]"
    Reg(R11) => "r11b"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}
