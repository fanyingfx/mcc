///|
typealias @utils.Counter

///|
pub fn emit_tacky(program : @parser.Program, counter : Counter) -> Program {
  let function_def = emit_function_def(program.function_def, counter)
  { function_def, }
}

///|
fn emit_function_def(
  function_def : @parser.FunctionDef,
  counter : Counter
) -> FunctionDef {
  let name = function_def.name
  let body = []
  for block_item in function_def.body._ {
    body.append(emit_block_item(block_item, counter))
  }
  body.push(Return(Constant(0)))
  { name, body }
}

///|
fn emit_block_item(
  block_item : @parser.BlockItem,
  counter : Counter
) -> Array[Instruction] {
  match block_item {
    D(decl) => emit_declaration(decl,counter)
    S(stmt) => emit_statement(stmt,counter)
  }
}

///|
fn emit_declaration(
  decl : @parser.Decl,
  counter : Counter
) -> Array[Instruction] {
  match decl.init {
    None => []
    Some(expr) => {
      let (instructions, result) = emit_expression(expr, counter)
      instructions.push(Copy(dst=Var(decl.name), src=result))
      instructions
    }
  }
}

///|
fn emit_statement(stmt : @parser.Stmt, counter : Counter) -> Array[Instruction] {
  match stmt {
    Return(expr) => {
      let (instructions, dst) = emit_expression(expr, counter)
      instructions.push(Return(dst))
      instructions
    }
    Expression(expr) => emit_expression(expr, counter).0
    Null => []
    If(cond, then, elze) => {
      let instructions = []
      let (cond_instrs, cond_val) = emit_expression(cond, counter)
      let then_instrs = emit_statement(then, counter)
      let else_instrs = match elze {
        Some(elze) => emit_statement(elze, counter)
        _ => []
      }
      let else_label = counter.make_label("else")
      let end_label = counter.make_label("end")
      let _ = instructions
        ..append(cond_instrs)
        ..push(JumpIfZero(cond_val, else_label))
        ..append(then_instrs)
        ..push(Jump(end_label))
        ..push(Label(else_label))
        ..append(else_instrs)
        ..push(Label(end_label))
      instructions
    }
    Compound(Block(block)) =>
      block.map(fn(block) { emit_block_item(block, counter) }).flatten()
  }
}

///|
fn emit_expression(
  expr : @parser.Expr,
  counter : Counter
) -> (Array[Instruction], Val) {
  match expr {
    Constant(c) => ([], Constant(c))
    Unary(op, inner) => {
      let (instructions, src) = emit_expression(inner, counter)
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      let tacky_op = convert_unop(op)
      instructions.push(Unary(tacky_op, dst~, src~))
      (instructions, dst)
    }
    Binary(_) => emit_binary(expr, counter)
    Var(v) => ([], Var(v))
    Assignment(left=Var(v), right~) => {
      let (instructions, result) = emit_expression(right, counter)
      instructions.push(Copy(dst=Var(v), src=result))
      (instructions, Var(v))
    }
    Conditional(cond~, then~, elze~) => {
      let instructions = []
      let (cond_instrs, cond_val) = emit_expression(cond, counter)
      let (then_instrs, then_val) = emit_expression(then, counter)
      let (else_instrs, else_val) = emit_expression(elze, counter)
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      let else_label = counter.make_label("else")
      let end_label = counter.make_label("end")
      let _ = instructions
        ..append(cond_instrs)
        ..push(JumpIfZero(cond_val, else_label))
        ..append(then_instrs)
        ..push(Copy(dst~, src=then_val))
        ..push(Jump(end_label))
        ..push(Label(else_label))
        ..append(else_instrs)
        ..push(Copy(dst~, src=else_val))
        ..push(Label(end_label))
      (instructions, dst)
    }
    _ => @utils.die("\{expr} Expression can not emit")
  }
}

///|
fn emit_binary(
  expr : @parser.Expr,
  counter : Counter
) -> (Array[Instruction], Val) {
  match expr {
    Binary(And, e1, e2) => {
      let instructions = []
      let (instructions1, v1) = emit_expression(e1, counter)
      let (instructions2, v2) = emit_expression(e2, counter)
      let false_label = counter.make_label("false")
      let end_label = counter.make_label("end")
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      let _ = instructions
        ..append(instructions1)
        ..push(JumpIfZero(v1, false_label))
        ..append(instructions2)
        ..push(JumpIfZero(v2, false_label))
        ..push(Copy(dst~, src=Constant(1)))
        ..push(Jump(end_label))
        ..push(Label(false_label))
        ..push(Copy(dst~, src=Constant(0)))
        ..push(Label(end_label))
      (instructions, dst)
    }
    Binary(Or, e1, e2) => {
      let instructions = []
      let (instructions1, v1) = emit_expression(e1, counter)
      let (instructions2, v2) = emit_expression(e2, counter)
      let true_label = counter.make_label("true")
      let end_label = counter.make_label("end")
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      let _ = instructions
        ..append(instructions1)
        ..push(JumpIfNotZero(v1, true_label))
        ..append(instructions2)
        ..push(JumpIfNotZero(v2, true_label))
        ..push(Copy(dst~, src=Constant(0)))
        ..push(Jump(end_label))
        ..push(Label(true_label))
        ..push(Copy(dst~, src=Constant(1)))
        ..push(Label(end_label))
      (instructions, dst)
    }
    Binary(op, e1, e2) => {
      let instructions = []
      let (instructions1, src1) = emit_expression(e1, counter)
      let (instructions2, src2) = emit_expression(e2, counter)
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      let tacky_op = convert_binop(op)
      instructions.append(instructions1)
      instructions.append(instructions2)
      instructions.push(Binary(tacky_op, dst~, src1~, src2~))
      (instructions, dst)
    }
    _ => @utils.die("Not a binary Expression")
  }
}

///|
fn convert_unop(op : @parser.UnaryOp) -> UnaryOp {
  match op {
    Complement => Complement
    Negate => Negate
    Not => Not
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
    Equal => Equal
    LessThan => LessThan
    NotEqual => NotEqual
    LessOrEqual => LessOrEqual
    GreaterThan => GreaterThan
    GreaterOrEqual => GreaterOrEqual
    _ => @utils.die("\{op} can be not covnerted")
  }
}

///|
test "tacky" {
  let content =
    #| int main(void){
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast, Counter::new())
  inspect!(
    tacky,
    content=
      #|{function_def: 
      #|main:
      #|  return Constant(3)
      #|  return Constant(0)}
    ,
  )
}

///|
test "tacky" {
  let content =
    #| int main(void){
    #|    return ~2;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast, Counter::new())
  inspect!(
    tacky,
    content=
      #|{function_def: 
      #|main:
      #|  Var("tmp.0") = ~Constant(2)
      #|  return Var("tmp.0")
      #|  return Constant(0)}
    ,
  )
}

///|
test "tacky" {
  let content =
    #| int main(void){
    #|    return -(~(-8));
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let tacky = emit_tacky(ast, Counter::new())
  inspect!(
    tacky,
    content=
      #|{function_def: 
      #|main:
      #|  Var("tmp.0") = -Constant(8)
      #|  Var("tmp.1") = ~Var("tmp.0")
      #|  Var("tmp.2") = -Var("tmp.1")
      #|  return Var("tmp.2")
      #|  return Constant(0)}
    ,
  )
}
