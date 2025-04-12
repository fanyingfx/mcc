///|
fn main {

  
  let content = @fs.read_file_to_string?("./examples/return2.c").unwrap()
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let asm = @asm.gen_program(ast)
  let asm_str = @emit.emit(asm)

  @fs.write_string_to_file?("./examples/return2.asm",asm_str).unwrap()
  
  
}
