///|
pub fn compile(program : @tacky.Program) -> Program {
  let asm_ast = gen_program(program)
  let (asm_ast,func_frame_map) = replace_pseudos(asm_ast)
  let asm_ast = fixup_program(asm_ast, func_frame_map)
  asm_ast
}
