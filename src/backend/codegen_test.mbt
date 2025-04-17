///|
test {
  let content =
    #| int main(void){
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = @tacky.emit_tacky(ast)
  let asm = @backend.compile(tacky)
  inspect!(
    asm,
    content=
      #|{function_def: {name: "main", instructions: [AllocateStack(0), Mov(dst=Reg(AX), src=Imm(3)), Ret]}}
    ,
  )
}
