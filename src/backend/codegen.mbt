///|
pub fn gen_program(program : @tacky.Program) -> Program {
  let function_defs = []
  for function_def in program.function_defs {
    let function_def = gen_function_def(function_def)
    function_defs.push(function_def)
  }
  { function_defs, }
}

///|
fn gen_function_def(func_def : @tacky.FunctionDecl) -> FunctionDef {
  let name = func_def.name
  let instructions = func_def.body.map(convert_instruction).flatten()
  { name, instructions }
}

///|
fn convert_instruction(instruction : @tacky.Instruction) -> Array[Instruction] {
  match instruction {
    Return(expr) => [Mov(dst=Reg(AX), src=convert_val(expr)), Ret]
    Unary(Not, dst~, src~) => {
      let src = convert_val(src)
      let dst = convert_val(dst)
      [Cmp(src, Imm(0)), Mov(dst~, src=Imm(0)), SetCC(E, dst)]
    }
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
    Binary(
      Equal
      | NotEqual
      | LessThan
      | LessOrEqual
      | GreaterThan
      | GreaterOrEqual as op,
      dst~,
      src1~,
      src2~
    ) => {
      let dst = convert_val(dst)
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let cond_code = convert_cond(op)
      [Cmp(src1, src2), Mov(dst~, src=Imm(0)), SetCC(cond_code, dst)]
    }
    Binary(op, dst~, src1~, src2~) => {
      let src1 = convert_val(src1)
      let src2 = convert_val(src2)
      let dst = convert_val(dst)
      let op = convert_binop(op)
      [Mov(dst~, src=src1), Binary(op, dst, src2)]
    }
    JumpIfZero(val, target) => {
      let val = convert_val(val)
      [Cmp(val, Imm(0)), JmpCC(E, target)]
    }
    JumpIfNotZero(val, target) => {
      let val = convert_val(val)
      [Cmp(val, Imm(0)), JmpCC(NE, target)]
    }
    Jump(target) => [Jmp(target)]
    Copy(dst~, src~) => {
      let dst = convert_val(dst)
      let src = convert_val(src)
      [Mov(dst~, src~)]
    }
    Label(l) => [Label(l)]
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
    _ => @utils.die("cannot convert unop \{op}")
  }
}

///|
fn convert_cond(op : @tacky.BinaryOp) -> CondCode {
  match op {
    LessThan => L
    LessOrEqual => LE
    Equal => E
    NotEqual => NE
    GreaterThan => G
    GreaterOrEqual => GE
    _ => @utils.die("\{op} is not a valid comparison operator")
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
