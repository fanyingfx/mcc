///|
pub fn compile(program : @tacky.Program) -> Program {
  let asm_ast = gen_program(program)
  let (asm_ast, stack_slot) = replace_pseudos(asm_ast)
  let asm_ast = fixup_program(asm_ast, stack_slot)
  asm_ast
}
