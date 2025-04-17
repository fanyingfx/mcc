///|
pub fn gen_program(program : @tacky.Program) -> Program {
  let function_def = gen_function_def(program.function_def)
  { function_def, }
}

///|
fn gen_function_def(func_def : @tacky.FunctionDef) -> FunctionDef {
  let name = func_def.name
  let instructions = func_def.body.map(convert_instruction).flatten()
  { name, instructions }
}

///|
fn convert_instruction(instruction : @tacky.Instruction) -> Array[Instruction] {
  match instruction {
    Return(expr) => [Mov(dst=Reg(AX), src=convert_val(expr)), Ret]
    Unary(op, dst~, src~) => {
      let dst = convert_val(dst)
      let src = convert_val(src)
      [Mov(dst~, src~), Unary(convert_unop(op), dst)]
    }
  }
}

///|
fn convert_val(val : @tacky.Val) -> Operand {
  match val {
    Constant(i) => Imm(i)
    Var(name) => Pseudo(name)
  }
}

///|
fn convert_unop(op : @tacky.UnaryOp) -> UnaryOp {
  match op {
    Complement => Not
    Negate => Neg
  }
}
