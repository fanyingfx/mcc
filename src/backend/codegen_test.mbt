///|
test {
  let content =
    #| int main(void){
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = @tacky.emit_tacky(validated_ast, symbol_table, counter)
  // let tacky = @tacky.emit_tacky(ast,@utils.Counter::new())
  let asm = @backend.compile(tacky,symbol_table)
  inspect!(
    asm,
    content=
      #|{top_levels: [Function(
      #|main:
      #|  AllocateStack(-16)
      #|  Mov(dst=Reg(AX), src=Imm(3))
      #|  Ret
      #|  Mov(dst=Reg(AX), src=Imm(0))
      #|  Ret)]}

    ,
  )
}
