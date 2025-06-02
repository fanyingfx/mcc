///|
let arg_registers : Array[Reg] = [DI, SI, DX, CX, R8, R9]

///|
pub fn gen_program(program : @tacky.Program) -> Program {
  let top_levels = []
  for def in program.toplevels {
    let def = match def {
      Function(func_def) => Function(gen_function_def(func_def))
      StaticVariable(name~, global~, init~) =>
        StaticVariable(name~, global~, init~)
    }
    // let def = gen_function_def(def)
    top_levels.push(def)
  }
  { top_levels, }
}

///|
fn gen_function_def(func_def : @tacky.FunctionDecl) -> FunctionDef {
  let name = func_def.name
  let instructions = []
  let (reg_params, stack_params) = split_at(func_def.params, 6)
  for i, param in reg_params {
    instructions.push(Mov(dst=Pseudo(param), src=Reg(arg_registers[i])))
  }
  for i, param in stack_params {
    let stk = Stack(16 + 8 * i)
    instructions.push(Mov(dst=Pseudo(param), src=stk))
  }
  let body_instructions = func_def.body.map(convert_instruction).flatten()
  instructions.append(body_instructions)
  { name, instructions, global: func_def.global }
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
    FuncCall(fname, args, dst) => convert_function_call(fname, args, dst)
  }
}

///|
fn convert_function_call(
  fname : String,
  args : Array[@tacky.Val],
  dst : @tacky.Val
) -> Array[Instruction] {
  let instructions = []
  let (register_args, stack_args) = split_at(args, 6)
  let stack_padding = if stack_args.length() % 2 != 0 { 8 } else { 0 }
  if stack_padding > 0 {
    instructions.push(AllocateStack(stack_padding))
  }
  // println("call \{fname}: \{register_args} \{stack_args}")
  for reg_index, tacky_arg in register_args {
    let r = arg_registers[reg_index]
    let assembly_arg = convert_val(tacky_arg)
    instructions.push(Mov(dst=Reg(r), src=assembly_arg))
  }

  // pass arg on stack, in reversed order
  for tacky_arg in stack_args.rev_iter() {
    let assembly_arg = convert_val(tacky_arg)
    if assembly_arg is (Reg(_) | Imm(_)) {
      instructions.push(Push(assembly_arg))
    } else {
      instructions
      ..push(Mov(dst=Reg(AX), src=assembly_arg))
      ..push(Push(Reg(AX)))
    }
  }
  instructions.push(Call(fname))

  // adjust stack pointer

  let bytes_to_remove = 8 * stack_args.length() + stack_padding
  if bytes_to_remove > 0 {
    instructions.push(DeallocateStack(bytes_to_remove))
  }
  let assembly_dst = convert_val(dst)
  instructions.push(Mov(src=Reg(AX), dst=assembly_dst))
  instructions
}

///|
fn[T] split_at(args : Array[T], index : Int) -> (Array[T], Array[T]) {
  if args.length() <= index {
    (args, [])
  } else {
    (args[:index].to_array(), args[index:].to_array())
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
