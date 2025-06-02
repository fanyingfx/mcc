///|
priv struct State {
  current_offset : Int
  offset_map : @immut/hashmap.T[String, Int]
}

///|
typealias FuncFrameMap = Map[String, Int]

///|
fn replace_pseudos(
  program : Program,
  symbol_table : @symbols.SymbolTable
) -> (Program, FuncFrameMap) {
  let state = State::{ current_offset: 0, offset_map: @immut/hashmap.new() }
  let func_frame_map = {}
  let top_levels = []
  for def in program.top_levels {
    let def = match def {
      Function(func_def) => {
        let (new_state, new_function_def) = state.replace_in_function_def(
          func_def, symbol_table,
        )
        func_frame_map[new_function_def.name] = new_state.current_offset
        Function(new_function_def)
      }
      StaticVariable(_) as def => def
    }
    top_levels.push(def)
  }
  ({ top_levels, }, func_frame_map)
}

///|
fn replace_in_function_def(
  self : State,
  function_def : FunctionDef,
  symbol_table : @symbols.SymbolTable
) -> (State, FunctionDef) {
  let name = function_def.name
  let global = function_def.global
  let instructions = []
  let mut state = self
  for instruction in function_def.instructions {
    let (new_state, new_instruction) = state.replace_in_instruction(
      instruction, symbol_table,
    )
    instructions.push(new_instruction)
    state = new_state
  }
  (state, { instructions, name, global })
}

///|
fn replace_in_instruction(
  self : State,
  instruction : Instruction,
  symbol_table : @symbols.SymbolTable
) -> (State, Instruction) {
  match instruction {
    Unary(op, operand) => {
      let (state1, new_operand) = self.replace_operand(operand, symbol_table)
      (state1, Unary(op, new_operand))
    }
    // Unary(op, self.replace_operand(operand,symbol_table))}
    Mov(dst~, src~) => {
      let (state1, dst) = self.replace_operand(dst, symbol_table)
      let (state2, src) = state1.replace_operand(src, symbol_table)
      (state2, Mov(dst~, src~))
    }
    Binary(op, e1, e2) => {
      let (state1, e1) = self.replace_operand(e1, symbol_table)
      let (state2, e2) = state1.replace_operand(e2, symbol_table)
      (state2, Binary(op, e1, e2))
    }
    Ret
    | Cdq
    | Jmp(_)
    | JmpCC(_, _)
    | Label(_)
    | Call(_)
    | DeallocateStack(_)
    | AllocateStack(_) as instruction => (self, instruction)
    Idiv(operand) => {
      let (state1, operand) = self.replace_operand(operand, symbol_table)
      (state1, Idiv(operand))
    }
    Cmp(operand1, operand2) => {
      let (state1, operand1) = self.replace_operand(operand1, symbol_table)
      let (state2, operand2) = state1.replace_operand(operand2, symbol_table)
      (state2, Cmp(operand1, operand2))
    }
    SetCC(cc, operand) => {
      let (state1, operand) = self.replace_operand(operand, symbol_table)
      (state1, SetCC(cc, operand))
    }
    Push(operand) => {
      let (state1, operand) = self.replace_operand(operand, symbol_table)
      (state1, Push(operand))
    }
    // AllocateStack(_)   as instr =>
    //   @utils.die("\{instr} should not be in replace pseudo")
  }
}

///|
fn replace_operand(
  self : State,
  operand : Operand,
  symbol_table : @symbols.SymbolTable
) -> (State, Operand) {
  match operand {
    Pseudo(s) => {
      if symbol_table.is_static(s) {
        return (self, Data(s))
      }
      match self.offset_map.get(s) {
        Some(offset) => (self, Stack(offset))
        None => {
          let current_offset = self.current_offset - 4
          let offset_map = self.offset_map.add(s, current_offset)
          ({ offset_map, current_offset }, Stack(current_offset))
        }
      }
    }
    operand => (self, operand)
  }
}
