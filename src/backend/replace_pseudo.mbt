///|
priv struct State {
  mut current_offset : Int
  offset_map : Map[String, Int]
}

///|
fn replace_pseudos(program : Program) -> (Program, Int) {
  let state = State::{ current_offset: 0, offset_map: {} }
  let function_def = state.replace_in_function_def(program.function_def)
  ({ function_def, }, state.current_offset)
}

///|
fn replace_in_function_def(
  self : State,
  function_def : FunctionDef
) -> FunctionDef {
  let name = function_def.name
  let instructions = []
  for instruction in function_def.instructions {
    instructions.push(self.replace_in_instruction(instruction))
  }
  { instructions, name }
}

///|
fn replace_in_instruction(
  self : State,
  instruction : Instruction
) -> Instruction {
  match instruction {
    Unary(op, operand) => Unary(op, self.replace_operand(operand))
    Mov(dst~, src~) => {
      let dst = self.replace_operand(dst)
      let src = self.replace_operand(src)
      Mov(dst~, src~)
    }
    Binary(op, e1, e2) => {
      let e1 = self.replace_operand(e1)
      let e2 = self.replace_operand(e2)
      Binary(op, e1, e2)
    }
    Ret | Cdq as instruction => instruction
    AllocateStack(_) =>
      @utils.die("AllocateStack should not be in replace pseudo")
    Idiv(operand) => {
      let operand = self.replace_operand(operand)
      Idiv(operand)
    }
  }
}

///|
fn replace_operand(self : State, operand : Operand) -> Operand {
  match operand {
    Pseudo(s) =>
      match self.offset_map[s] {
        Some(offset) => Stack(offset)
        None => {
          let new_offset = self.current_offset - 4
          self.current_offset = new_offset
          self.offset_map[s] = new_offset
          Stack(new_offset)
        }
      }
    operand => operand
  }
}
