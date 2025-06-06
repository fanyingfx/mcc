///|
typealias @utils.Counter

///|
pub fn emit_tacky(
  program : @parser.Program,
  symbol_table : @symbols.SymbolTable,
  counter : Counter
) -> Program {
  let function_defs = []
  for decl in program.decls {
    match decl {
      FuncDecl(func_decl) =>
        if func_decl.body is Some(body) {
          let function_def = emit_function_def(
            func_decl.name,
            func_decl.params,
            body,
            symbol_table,
            counter,
          )
          function_defs.push(Function(function_def))
        }
      VarDecl(_) => continue
    }
  }
  let var_defs = convert_symbols_to_tacky(symbol_table)
  { toplevels: var_defs + function_defs }
}

///|
fn convert_symbols_to_tacky(
  symbol_table : @symbols.SymbolTable
) -> Array[TopLevel] {
  let tacky_defs = []
  for name, entry in symbol_table._ {
    match entry.attrs {
      StaticAttr(init, global) =>
        match init {
          Initial(i) => tacky_defs.push(StaticVariable(name~, global~, init=i))
          Tentative => tacky_defs.push(StaticVariable(name~, global~, init=0))
          NoInitializer => continue
        }
      _ => continue
    }
  }
  tacky_defs
}

///|
fn emit_function_def(
  function_name : String,
  params : Array[String],
  function_body : @parser.Block,
  symbol_table : @symbols.SymbolTable,
  counter : Counter
) -> FunctionDecl {
  let name = function_name
  let global = symbol_table.is_global(name)
  let body = []
  for block_item in function_body._ {
    body.append(emit_block_item(block_item, counter))
  }
  body.push(Return(Constant(0)))
  { name, params, body, global }
}

///|
fn emit_block_item(
  block_item : @parser.BlockItem,
  counter : Counter
) -> Array[Instruction] {
  match block_item {
    D(VarDecl({ storage_class: Some(_), .. })) => []
    D(VarDecl(var_decl)) => emit_variable_declaration(var_decl, counter)
    S(stmt) => emit_statement(stmt, counter)
    D(FuncDecl(_)) => []
  }
}


///|
fn emit_variable_declaration(
  decl : @parser.VariableDecl,
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
      instructions
      ..append(cond_instrs)
      ..push(JumpIfZero(cond_val, else_label))
      ..append(then_instrs)
      ..push(Jump(end_label))
      ..push(Label(else_label))
      ..append(else_instrs)
      ..push(Label(end_label))
      instructions
    }
    Compound(Block(block)) => block.map(emit_block_item(_, counter)).flatten()
    Continue(label) => [Jump(continue_label(label))]
    Break(label) => [Jump(break_label(label))]
    While(cond, body, label) => {
      let instructions = []
      let cont_label = continue_label(label)
      let brk_label = break_label(label)
      let (cond_instrs, cond_val) = emit_expression(cond, counter)
      let body_instrs = emit_statement(body, counter)
      instructions
      ..push(Label(cont_label))
      ..append(cond_instrs)
      ..push(JumpIfZero(cond_val, brk_label))
      ..append(body_instrs)
      ..push(Jump(cont_label))
      ..push(Label(brk_label))
      instructions
    }
    DoWhile(body, cond, label) => {
      let instructions = []
      let start_label = counter.make_label("do_while_start")
      let cont_label = continue_label(label)
      let brk_label = break_label(label)
      let body_instrs = emit_statement(body, counter)
      let (cond_instrs, cond_val) = emit_expression(cond, counter)
      instructions
      ..push(Label(start_label))
      ..append(body_instrs)
      ..push(Label(cont_label))
      ..append(cond_instrs)
      ..push(JumpIfNotZero(cond_val, start_label))
      ..push(Label(brk_label))
      instructions
    }
    For(init, cond~, post~, body, label) => {
      let instructions = []
      let start_label = counter.make_label("for_start")
      let cont_label = continue_label(label)
      let brk_label = break_label(label)
      let init_instrs = match init {
        InitDecl(decl) => emit_variable_declaration(decl, counter)
        InitExpr(expr_opt) =>
          match expr_opt {
            Some(expr) => emit_expression(expr, counter).0
            None => []
          }
      }
      let cond_instrs = match cond {
        Some(expr) => {
          let (expr_instrs, cond_val) = emit_expression(expr, counter)
          expr_instrs.push(JumpIfZero(cond_val, brk_label))
          expr_instrs
        }
        None => []
      }
      let post_instrs = match post {
        Some(expr) => emit_expression(expr, counter).0
        None => []
      }
      let body_instrs = emit_statement(body, counter)
      instructions
      ..append(init_instrs)
      ..push(Label(start_label))
      ..append(cond_instrs)
      ..append(body_instrs)
      ..push(Label(cont_label))
      ..append(post_instrs)
      ..push(Jump(start_label))
      ..push(Label(brk_label))
      instructions
    }
  }
}

///|
fn break_label(label : String) -> String {
  "\{label}_break"
}

///|
fn continue_label(label : String) -> String {
  "\{label}_continue"
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
      instructions
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
    FunctionCall(fname, args) => {
      let instructions = []
      let arg_vals = []
      let dst_name = counter.make_temporary()
      let dst = Var(dst_name)
      for arg in args {
        let (arg_instrs, val) = emit_expression(arg, counter)
        instructions.append(arg_instrs)
        arg_vals.push(val)
      }
      instructions.push(FuncCall(fname, arg_vals, dst))
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
      instructions
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
      instructions
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
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = emit_tacky(validated_ast, symbol_table, counter)
  inspect!(
    tacky,
    content=
      #|{toplevels: [Function(
      #|main:
      #|  return Constant(3)
      #|  return Constant(0))]}
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
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = emit_tacky(validated_ast, symbol_table, counter)
  inspect!(
    tacky,
    content=
      #|{toplevels: [Function(
      #|main:
      #|  Var("tmp.0") = ~Constant(2)
      #|  return Var("tmp.0")
      #|  return Constant(0))]}
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
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = emit_tacky(validated_ast, symbol_table, counter)
  inspect!(
    tacky,
    content=
      #|{toplevels: [Function(
      #|main:
      #|  Var("tmp.0") = -Constant(8)
      #|  Var("tmp.1") = ~Var("tmp.0")
      #|  Var("tmp.2") = -Var("tmp.1")
      #|  return Var("tmp.2")
      #|  return Constant(0))]}
    ,
  )
}

///|
test "tacky" {
  let content =
    #|int x = 1;
    #|int y;
    #| int main(void){
    #| int z =0;
    #|    return x+z;
    #|}
  let tokens = @lexer.lex(content)
  let ast = @parser.parse(tokens)
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  let tacky = emit_tacky(validated_ast, symbol_table, counter)
  inspect!(
    tacky,
    content=
      #|{toplevels: [StaticVariable(name="x", global=true, init=1), StaticVariable(name="y", global=true, init=0), Function(
      #|main:
      #|  Var("z.0") = Constant(0)
      #|  Var("tmp.1") = Var("x") + Var("z.0")
      #|  return Var("tmp.1")
      #|  return Constant(0))]}
    ,
  )
}
