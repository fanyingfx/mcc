///|
pub fn fixup_program(
  program : Program,
  func_frame_map : FuncFrameMap
) -> Program {
  let top_levels = []
  for def in program.top_levels {
    let fixed_def : TopLevel = match def {
      Function(func_def) => {
        let fixed_func_def = fixup_function_def(
          func_def,
          func_frame_map.get(func_def.name).unwrap(),
        )
        Function(fixed_func_def)
      }
      StaticVariable(_) as static_var => static_var
    }
    top_levels.push(fixed_def)
  }
  { top_levels, }
}

///|
fn fixup_function_def(
  function_def : FunctionDef,
  last_stack_slot : Int
) -> FunctionDef {
  let instructions = []
  let global = function_def.global
  instructions.push(
    AllocateStack(@utils.round_away_from_zero(-last_stack_slot, base=16)),
  )
  for instruction in function_def.instructions {
    instructions.append(fixup_instruction(instruction))
  }
  { name: function_def.name, instructions, global }
}

///|
fn fixup_instruction(instruction : Instruction) -> Array[Instruction] {
  match instruction {
    Mov(dst=Stack(_) | Data(_) as dst, src=Stack(_) | Data(_) as src) =>
      [Mov(dst=Reg(R10), src~), Mov(dst~, src=Reg(R10))]
    Binary(Add | Sub as op, Stack(_) | Data(_) as e1, Stack(_) | Data(_) as e2) =>
      [Mov(dst=Reg(R10), src=e2), Binary(op, e1, Reg(R10))]
    Binary(Mul, Stack(_) | Data(_) as e1, e2) =>
      [
        Mov(dst=Reg(R11), src=e1),
        Binary(Mul, Reg(R11), e2),
        Mov(dst=e1, src=Reg(R11)),
      ]
    Idiv(Imm(_) as imm) => [Mov(dst=Reg(R10), src=imm), Idiv(Reg(R10))]
    Cmp(Stack(_) | Data(_) as e1, Stack(_) | Data(_) as e2) =>
      [Mov(dst=Reg(R10), src=e2), Cmp(e1, Reg(R10))]
    Cmp(Imm(_) as imm, e) => [Mov(dst=Reg(R11), src=imm), Cmp(Reg(R11), e)]
    other => [other]
  }
}
