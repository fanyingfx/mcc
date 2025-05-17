///|
pub fn fixup_program(program : Program, func_frame_map : FuncFrameMap) -> Program {
  let function_defs = []
  for function_def in program.function_defs{
    let fixed_function_def = fixup_function_def(function_def,func_frame_map.get(function_def.name).unwrap())
    function_defs.push(fixed_function_def)
  }
  { function_defs,}
}

///|
fn fixup_function_def(
  function_def : FunctionDef,
  last_stack_slot : Int
) -> FunctionDef {
  let instructions = []
  instructions.push(AllocateStack(-last_stack_slot))
  for instruction in function_def.instructions {
    instructions.append(fixup_instruction(instruction))
  }
  { name: function_def.name, instructions }
}

///|
fn fixup_instruction(instruction : Instruction) -> Array[Instruction] {
  match instruction {
    Mov(dst=Stack(_) as dst, src=Stack(_) as src) =>
      [Mov(dst=Reg(R10), src~), Mov(dst~, src=Reg(R10))]
    Binary(Add | Sub as op, Stack(_) as e1, Stack(_) as e2) =>
      [Mov(dst=Reg(R10), src=e2), Binary(op, e1, Reg(R10))]
    Binary(Mul, Stack(_) as e1, e2) =>
      [
        Mov(dst=Reg(R11), src=e1),
        Binary(Mul, Reg(R11), e2),
        Mov(dst=e1, src=Reg(R11)),
      ]
    Idiv(Imm(_) as imm) => [Mov(dst=Reg(R10), src=imm), Idiv(Reg(R10))]
    Cmp(Stack(_) as e1, Stack(_) as e2) =>
      [Mov(dst=Reg(R10), src=e2), Cmp(e1, Reg(R10))]
    Cmp(Imm(_) as imm, e) => [Mov(dst=Reg(R11), src=imm), Cmp(Reg(R11), e)]
    other => [other]
  }
}
