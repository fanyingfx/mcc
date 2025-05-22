///|
priv trait ShowOp {
  str(Self) -> String
}

///|
priv trait ShowOperand {
  byte(Self) -> String
  dword(Self) -> String
  qword(Self) -> String
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

///|
let obj_header =
  #|format ELF64
  #|section ".text" writeable
  #|

///|
pub fn emit(
  program : @backend.Program,
  symbol_table : @semantic_analysis.SymbolTable
) -> String {
  let extern_functions = []
  let export_functions = []
  println(symbol_table)
  for fname, entry in symbol_table._ {
    if @semantic_analysis.is_function(entry.ty) {
      if entry.has_defined {
        export_functions.push("public _\{fname} as '\{fname}'")
      } else {
        extern_functions.push("extrn '\{fname}' as _\{fname}")
      }
    }
  }
  // println(extern_functions)
  let extrn_functions_decl = extern_functions.join("\n") + "\n"
  let export_functions = export_functions.join("\n") + "\n"
  let function_asm = program.function_defs.map(emit_function(_)).join("\n")
  obj_header + extrn_functions_decl + export_functions + function_asm
}

///|
fn emit_function(
  function_def : @backend.FunctionDef
) -> String {
  let func_name = show_function_name(function_def.name)
  let instructions = function_def.instructions.map(fn(instruction) {
    "  " + emit_instruction(instruction)
  })
  $|\{func_name}:
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
    DeallocateStack(i) => "add rsp, \{i}"
    Push(operand) => "push \{operand.qword()}"
    Call(fname) => "call \{show_function_name(fname)}"
  }
  instrction + "\n"
}

///|
fn show_function_name(
  fname : String
  // symbol_table : @semantic_analysis.SymbolTable
) -> String {
  // if fname == "main" {
  //   return fname
  // }
  // if fasm_keywords.contains(fname) {
  return "_" + fname
  // }
  // fname
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
impl ShowOperand for @backend.Operand with qword(self) {
  match self {
    Imm(i) => i.to_string()
    Reg(AX) => "rax"
    Reg(R10) => "r10"
    Stack(i) => "qword [rbp + \{i}]"
    Reg(DX) => "rdx"
    Reg(R11) => "r11"
    Reg(DI) => "rdi"
    Reg(SI) => "rsi"
    Reg(CX) => "rcx"
    Reg(R8) => "r8"
    Reg(R9) => "r9"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}

///|
impl ShowOperand for @backend.Operand with dword(self) {
  match self {
    Imm(i) => i.to_string()
    Reg(AX) => "eax"
    Reg(R10) => "r10d"
    Stack(i) => "dword [rbp + \{i}]"
    Reg(DX) => "edx"
    Reg(R11) => "r11d"
    Reg(DI) => "edi"
    Reg(SI) => "esi"
    Reg(CX) => "ecx"
    Reg(R8) => "r8d"
    Reg(R9) => "r9d"
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
    Stack(i) => "byte [rbp + \{i}]"
    Reg(R11) => "r11b"
    Reg(DI) => "dil"
    Reg(SI) => "sil"
    Reg(CX) => "cl"
    Reg(R8) => "r8b"
    Reg(R9) => "r9b"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}
