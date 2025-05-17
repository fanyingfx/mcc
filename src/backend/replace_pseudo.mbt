///|
priv struct State {
  current_offset : Int
  offset_map : @immut/hashmap.T[String, Int]
}

///|
typealias FuncFrameMap = Map[String, Int]

///|
fn replace_pseudos(program : Program) -> (Program, FuncFrameMap) {
  let state = State::{ current_offset: 0, offset_map: @immut/hashmap.new() }
  let func_frame_map = {}
  let function_defs = []
  for function_def in program.function_defs {
    let (new_state, new_function_def) = state.replace_in_function_def(
      function_def,
    )
    function_defs.push(new_function_def)
    func_frame_map[new_function_def.name] = new_state.current_offset
  }
  ({ function_defs, }, func_frame_map)
}

///|
fn replace_in_function_def(
  self : State,
  function_def : FunctionDef
) -> (State, FunctionDef) {
  let name = function_def.name
  let instructions = []
  let mut state = self
  for instruction in function_def.instructions {
    let (new_state, new_instruction) = state.replace_in_instruction(instruction)
    instructions.push(new_instruction)
    state = new_state
  }
  (state, { instructions, name })
}

///|
fn replace_in_instruction(
  self : State,
  instruction : Instruction
) -> (State, Instruction) {
  match instruction {
    Unary(op, operand) => {
      let (state1, new_operand) = self.replace_operand(operand)
      (state1, Unary(op, new_operand))
    }
    // Unary(op, self.replace_operand(operand))}
    Mov(dst~, src~) => {
      let (state1, dst) = self.replace_operand(dst)
      let (state2, src) = state1.replace_operand(src)
      (state2, Mov(dst~, src~))
    }
    Binary(op, e1, e2) => {
      let (state1, e1) = self.replace_operand(e1)
      let (state2, e2) = state1.replace_operand(e2)
      (state2, Binary(op, e1, e2))
    }
    Ret | Cdq | Jmp(_) | JmpCC(_, _) | Label(_) as instruction =>
      (self, instruction)
    AllocateStack(_) =>
      @utils.die("AllocateStack should not be in replace pseudo")
    Idiv(operand) => {
      let (state1, operand) = self.replace_operand(operand)
      (state1, Idiv(operand))
    }
    Cmp(operand1, operand2) => {
      let (state1, operand1) = self.replace_operand(operand1)
      let (state2, operand2) = state1.replace_operand(operand2)
      (state2, Cmp(operand1, operand2))
    }
    SetCC(cc, operand) => {
      let (state1, operand) = self.replace_operand(operand)
      (state1, SetCC(cc, operand))
    }
  }
}

///|
fn replace_operand(self : State, operand : Operand) -> (State, Operand) {
  match operand {
    Pseudo(s) =>
      match self.offset_map.get(s) {
        Some(offset) => (self, Stack(offset))
        None => {
          let current_offset = self.current_offset - 4
          let offset_map = self.offset_map.add(s, current_offset)
          ({ offset_map, current_offset }, Stack(current_offset))
        }
      }
    operand => (self, operand)
  }
}
