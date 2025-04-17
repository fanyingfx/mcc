pub fn gen_program(program:@parser.Program)->Program{
  let function_def = gen_function_def(program.function_def)
  Program::{function_def}

}

fn gen_function_def(func_def:@parser.FunctionDef)->FunctionDef{
  let name = func_def.name
  let instructions = gen_stmt(func_def.body)
  {name,instructions}
}
fn gen_stmt(stmt:@parser.Stmt)->Array[Instruction]{
  match stmt{
    Return(expr) => [
      Mov(dst=Register,src=gen_expr(expr)),
      Ret
    ]
  }
}
fn gen_expr(expr:@parser.Expr)->Operand{
  match expr{
    Constant(i) => Imm(i)
    _ =>panic()
  }
}


test{
  let content = 
  #| int main(void){
  #|    return 3;
  #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let asm = gen_program(ast)

  inspect!(asm, content=
    #|{function_def: {name: "main", instructions: [Mov(dst=Register, src=Imm(3)), Ret]}}

  )
 
}