///|
typealias @parser.(Decl, Stmt, Expr, BlockItem, Block, FunctionDef, Program)

///|
typealias @utils.Counter

///|
priv type VariableMap Map[String, Entry]

///|
priv struct Entry {
  new_name : String
  from_current_block : Bool
}

///|
fn copy(self : VariableMap) -> VariableMap {
  let new_variable_map = {}
  for k, v in self._ {
    new_variable_map[k] = { new_name: v.new_name, from_current_block: false }
  }
  new_variable_map
}

///|
pub fn resolve(program : Program, counter : Counter) -> Program {
  let variable_map : VariableMap = {}
  let function_def = variable_map.resolve_function_def(
    program.function_def,
    counter,
  )
  { function_def, }
}

///|
fn resolve_function_def(
  self : VariableMap,
  function_def : FunctionDef,
  counter : Counter
) -> FunctionDef {
  {
    name: function_def.name,
    body: self.resolve_block(function_def.body, counter),
  }
}

///|
fn resolve_block(self : VariableMap, block : Block, counter : Counter) -> Block {
  let body = []
  for block_item in block._ {
    body.push(self.resolve_block_item(block_item, counter))
  }
  body
}

///|
fn resolve_block_item(
  self : VariableMap,
  block_item : BlockItem,
  counter : Counter
) -> BlockItem {
  match block_item {
    S(stmt) => S(self.resovle_statement(stmt, counter))
    D(decl) => D(self.resolve_declaration(decl, counter))
  }
}

///|
fn resolve_declaration(
  self : VariableMap,
  decl : Decl,
  counter : Counter
) -> Decl {
  if self._.get(decl.name) is Some(entry) && entry.from_current_block {
    @utils.die("Duplicate variable declaration!")
  }
  let unique_name = counter.make_label(decl.name + ".")
  self._[decl.name] = { new_name: unique_name, from_current_block: true }
  let init = match decl.init {
    Some(expr) => Some(self.resolve_expression(expr))
    None => None
  }
  { name: unique_name, init }
}

///|
fn resovle_statement(
  self : VariableMap,
  stmt : Stmt,
  counter : Counter
) -> Stmt {
  match stmt {
    Expression(e) => Expression(self.resolve_expression(e))
    Return(e) => Return(self.resolve_expression(e))
    If(cond, then, elze) => {
      let cond = self.resolve_expression(cond)
      let then = self.resovle_statement(then, counter)
      let elze = elze.map(fn { st => self.resovle_statement(st, counter) })
      If(cond, then, elze)
    }
    Compound(Block(block)) => {
      let new_varialbe_map = self.copy()
      Compound(new_varialbe_map.resolve_block(block, counter))
    }
    While(cond, stmt, label) => {
      let cond = self.resolve_expression(cond)
      let stmt = self.resovle_statement(stmt, counter)
      While(cond, stmt, label)
    }
    Null | Break(_) | Continue(_) as s => s
    DoWhile(body, cond, label) => {
      let cond = self.resolve_expression(cond)
      let body = self.resovle_statement(body, counter)
      DoWhile(body, cond, label)
    }
    For(init, cond~, post~, body, label) => {
      let new_variable_map = self.copy()
      let init = new_variable_map.resolve_for_init(init,counter)
      let cond = cond.map(fn{expr => new_variable_map.resolve_expression(expr)})
      let post = post.map(fn {expr => new_variable_map.resolve_expression(expr)})
      let body = new_variable_map.resovle_statement(body,counter)
      For(init,cond~,post~,body,label)

    }
  }
}

///|
fn resolve_expression(self : VariableMap, expr : Expr) -> Expr {
  match expr {
    Binary(op, left, right) =>
      Binary(op, self.resolve_expression(left), self.resolve_expression(right))
    Unary(op, expr) => Unary(op, self.resolve_expression(expr))
    Var(v) =>
      match self._.get(v) {
        Some({ new_name, .. }) => Var(new_name)
        None => @utils.die("Undeclared variable '\{v}'")
      }
    Constant(i) => Constant(i)
    Assignment(left~, right~) => {
      if not(left is Var(_)) {
        @utils.die("Invalid lvalue!")
      }
      Assignment(
        left=self.resolve_expression(left),
        right=self.resolve_expression(right),
      )
    }
    Conditional(cond~, then~, elze~) => {
      let cond = self.resolve_expression(cond)
      let then = self.resolve_expression(then)
      let elze = self.resolve_expression(elze)
      Conditional(cond~, then~, elze~)
    }
  }
}

///|
fn resolve_for_init(
  self : VariableMap,
  init : @parser.ForInit,
  counter : @utils.Counter
) -> @parser.ForInit {
  match init {
    InitDecl(decl) => InitDecl(self.resolve_declaration(decl, counter))
    InitExpr(expr_opt) =>
      InitExpr(expr_opt.map(fn { exp => self.resolve_expression(exp) }))
  }
}
