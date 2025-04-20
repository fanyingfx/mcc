///|
pub fn emit_tacky(program : @parser.Program) -> Program {
  let function_def = emit_function_def(program.function_def)
  { function_def, }
}

///|
fn emit_function_def(function_def : @parser.FunctionDef) -> FunctionDef {
  let name = function_def.name
  let body = emit_stmt(function_def.body)
  { name, body }
}

///|
fn emit_stmt(stmt : @parser.Stmt) -> Array[Instruction] {
  match stmt {
    Return(expr) => {
      let (instructions, dst) = emit_expr(expr)
      instructions.push(Return(dst))
      instructions
    }
  }
}

///|
fn emit_expr(expr : @parser.Expr) -> (Array[Instruction], Val) {
  match expr {
    Constant(c) => ([], Constant(c))
    Unary(op, inner) => {
      let (instructions, src) = emit_expr(inner)
      let dst_name = @utils.make_temporary()
      let dst = Var(dst_name)
      let tacky_op = convert_unop(op)
      instructions.push(Unary(tacky_op, dst~, src~))
      (instructions, dst)
    }
    Binary(op, e1, e2) => {
      let instructions = []
      let (instructions1, src1) = emit_expr(e1)
      let (instructions2, src2) = emit_expr(e2)
      let dst_name = @utils.make_temporary()
      let dst = Var(dst_name)
      let tacky_op = convert_binop(op)
      instructions.append(instructions1)
      instructions.append(instructions2)
      instructions.push(Binary(tacky_op, dst~, src1~, src2~))
      (instructions, dst)
    }
  }
}


///|
fn convert_unop(op : @parser.UnaryOp) -> UnaryOp {
  match op {
    Complement => Complement
    Negate => Negate
  }
}

///|
fn convert_binop(op : @parser.BinaryOp) -> BinaryOp {
  match op {
    Div => Div
    Mul => Mul
    Sub => Sub
    Add => Add
    Rem => Rem
  }
}

///|
test "tacky" {
  @utils.reset_counter()
  let content =
    #| int main(void){
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast)
  inspect!(
    tacky,
    content=
      #|{function_def: {name: "main", body: [Return(Constant(3))]}}
    ,
  )
}

///|
test "tacky" {
  @utils.reset_counter()
  let content =
    #| int main(void){
    #|    return ~2;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast)
  inspect!(
    tacky,
    content=
      #|{function_def: {name: "main", body: [Unary(Complement, dst=Var("tmp.0"), src=Constant(2)), Return(Var("tmp.0"))]}}
    ,
  )
}

///|
test "tacky" {
  @utils.reset_counter()
  let content =
    #| int main(void){
    #|    return -(~(-8));
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast)
  inspect!(
    tacky,
    content=
      #|{function_def: {name: "main", body: [Unary(Negate, dst=Var("tmp.0"), src=Constant(8)), Unary(Complement, dst=Var("tmp.1"), src=Var("tmp.0")), Unary(Negate, dst=Var("tmp.2"), src=Var("tmp.1")), Return(Var("tmp.2"))]}}
    ,
  )
}
