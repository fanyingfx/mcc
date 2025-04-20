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
    Binary(Div, dst~, src1~, src2~) => {
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let dst = convert_val(dst)
      [Mov(dst=Reg(AX), src=src1), Cdq, Idiv(src2), Mov(dst~, src=Reg(AX))]
    }
    Binary(Rem, dst~, src1~, src2~) => {
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let dst = convert_val(dst)
      [Mov(dst=Reg(AX), src=src1), Cdq, Idiv(src2), Mov(dst~, src=Reg(DX))]
    }
    Binary(op, dst~, src1~, src2~) => {
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let dst = convert_val(dst)
      let op = convert_binop(op)
      [Mov(dst~, src=src1), Binary(op, dst, src2)]
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

///|
fn convert_binop(op : @tacky.BinaryOp) -> BinaryOp {
  match op {
    Mul => Mul
    Sub => Sub
    Add => Add
    op => @utils.die("\{op} cannot be converted!")
  }
}
