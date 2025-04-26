///|
priv type VariableMap Map[String, String]

///|
typealias @parser.(Decl, Stmt, Expr, BlockItem, FunctionDef, Program)

///|
pub fn resolve(program : Program) -> Program {
  let variable_map : VariableMap = {}
  let function_def = variable_map.resolve_function_def(program.function_def)
  { function_def, }
}

///|
fn resolve_function_def(
  self : VariableMap,
  function_def : FunctionDef
) -> FunctionDef {
  let body = []
  for block_item in function_def.body {
    body.push(self.resolve_block_item(block_item))
  }
  { name: function_def.name, body }
}

///|
fn resolve_block_item(self : VariableMap, block_item : BlockItem) -> BlockItem {
  match block_item {
    S(stmt) => S(self.resovle_statement(stmt))
    D(decl) => D(self.resolve_declaration(decl))
  }
}

///|
fn resolve_declaration(self : VariableMap, decl : Decl) -> Decl {
  if self._.contains(decl.name) {
    @utils.die("Duplicate variable declaration!")
  }
  let unique_name = @utils.make_label(decl.name)
  self._[decl.name] = unique_name
  let init = match decl.init {
    Some(expr) => Some(self.resolve_expression(expr))
    None => None
  }
  { name: unique_name, init }
}

///|
fn resovle_statement(self : VariableMap, stmt : Stmt) -> Stmt {
  match stmt {
    Expression(e) => Expression(self.resolve_expression(e))
    Return(e) => Return(self.resolve_expression(e))
    Null => Null
  }
}

///|
fn resolve_expression(self : VariableMap, expr : Expr) -> Expr {
  match expr {
    Binary(op, left, right) =>
      Binary(op, self.resolve_expression(left), self.resolve_expression(right))
    Unary(op, expr) => Unary(op, self.resolve_expression(expr))
    Var(v) =>
      match self._[v] {
        Some(name) => Var(name)
        None => @utils.die("Undeclared variable~")
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
  }
}
