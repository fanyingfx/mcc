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
  #|

///|
let code_header = "section \".text\" writeable\n"

///|
pub fn emit(
  program : @backend.Program,
  symbol_table : @symbols.SymbolTable
) -> String {
  let extern_functions = []
  let extern_vars = []
  let export_functions = []
  let export_vars = []
  let function_defs = []
  let bss_decls = []
  let data_decls = []
  for decl in program.top_levels {
    match decl {
      Function(func_def) => function_defs.push(func_def)
      StaticVariable(name~, init=0, ..) => bss_decls.push("  \{name} rd 1")
      StaticVariable(name~, init~, ..) =>
        data_decls.push("  \{name} dd \{init}")
    }
  }
  println(symbol_table._)
  for name, entry in symbol_table._ {
    match entry.attrs {
      FuncAttr(defined~, global=true) =>
        if defined {
          export_functions.push("public _\{name} as '\{name}'")
        } else {
          extern_functions.push("extrn '\{name}' as _\{name}")
        }
      StaticAttr(NoInitializer, true) => extern_vars.push("extrn \{name}")
      StaticAttr(_, true) => export_vars.push("public \{name}")
      _ => ()
    }
  }
  // println(extern_functions)
  let extrn_functions_decl = extern_functions.join("\n") + "\n"
  let extrn_vars_decl = extern_vars.join("\n") + "\n"
  let export_functions = export_functions.join("\n") + "\n"
  let export_vars = export_vars.join("\n")+"\n"
  let function_asm = function_defs.map(emit_function(_)).join("\n")
  let bss_decls = bss_decls.join("\n")
  let bss_seg =
    #|section ".bss" writeable
    #|  align 4
    $|\{bss_decls}
    #|
  let data_decls = data_decls.join("\n")
  let data_seg =
    #|section ".data" writeable
    #|  align 4
    $|\{data_decls}
    #|
  obj_header +
  data_seg +
  bss_seg +
  extrn_functions_decl +
  extrn_vars_decl +
  export_functions +
  export_vars+
  code_header +
  function_asm
}

///|
fn emit_function(function_def : @backend.FunctionDef) -> String {
  let func_name = show_function_name(function_def.name)
  let instructions = function_def.instructions.map(fn(instruction) {
    "  " + emit_instruction(instruction)
  })
  let instructions = instructions.join("")
  $|\{func_name}:
  #|  push rbp
  #|  mov  rbp, rsp
  $|\{instructions}
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
    Data(name) => "qword [\{name}]"
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
    Data(name) => "dword [\{name}]"
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
    Data(name) => "byte [\{name}]"
    Pseudo(_) => @utils.die("Pseudo should not in emit pass")
  }
}
