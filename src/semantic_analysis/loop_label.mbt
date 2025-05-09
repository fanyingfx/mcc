///|
pub fn loop_label(
  program : @parser.Program,
  counter : @utils.Counter
) -> @parser.Program {
  let function_def = label_function_def(program.function_def, None, counter)
  { function_def, }
}

///|
fn label_function_def(
  func_def : @parser.FunctionDef,
  label : String?,
  counter : @utils.Counter
) -> @parser.FunctionDef {
  { name: func_def.name, body: label_block(func_def.body, label, counter) }
}

///|
fn label_block(
  block : @parser.Block,
  label : String?,
  counter : @utils.Counter
) -> @parser.Block {
  block._.map(label_block_item(_, label, counter))
}

///|
fn label_block_item(
  item : @parser.BlockItem,
  label : String?,
  counter : @utils.Counter
) -> @parser.BlockItem {
  match item {
    S(stmt) => S(label_statement(stmt, label, counter))
    d => d
  }
}

///|
fn label_statement(
  stmt : @parser.Stmt,
  current_label : String?,
  counter : @utils.Counter
) -> @parser.Stmt {
  match stmt {
    Compound(block) => {
      let block : Array[@parser.BlockItem] = block._.map(fn {
        S(stmt) => S(label_statement(stmt, current_label, counter))
        D(decl) => D(decl)
      })
      Compound(block)
    }
    If(cond, then, elze) => {
      let then = label_statement(then, current_label, counter)
      let elze = elze.map(label_statement(_, current_label, counter))
      If(cond, then, elze)
    }
    While(cond, body, _) => {
      let new_label = counter.make_label("while_loop")
      let body = label_statement(body, Some(new_label), counter)
      While(cond, body, new_label)
    }
    DoWhile(body, cond, _) => {
      let new_label = counter.make_label("do_while_loop")
      let body = label_statement(body, Some(new_label), counter)
      DoWhile(body, cond, new_label)
    }
    For(init, cond~, post~, body, _) => {
      let new_label = counter.make_label("for_loop")
      let labeled_body = label_statement(body, Some(new_label), counter)
      For(init, cond~, post~, labeled_body, new_label)
    }
    Continue(_) => {
      if current_label is Some(l) {
        return Continue(l)
      }
      @utils.die("continue statement is out of loop")
    }
    Break(_) => {
      if current_label is Some(l) {
        return Break(l)
      }
      @utils.die("break statement is out of loop")
    }
    Expression(_) | Return(_) | Null as s => s
  }
}
