///|
pub fn fixup_program(program : Program, last_stack_slot : Int) -> Program {
  { function_def: fixup_function_def(program.function_def, last_stack_slot) }
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
    other => [other]
  }
}
