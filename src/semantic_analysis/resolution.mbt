///|
typealias @parser.(
  VariableDecl,
  Stmt,
  Expr,
  BlockItem,
  Block,
  FunctionDecl,
  Program
)

///|
typealias @utils.Counter

///|
priv type IdentifierMap Map[String, Entry]

///|
priv struct Entry {
  unique_name : String
  from_current_block : Bool
  has_linkage : Bool
}

///|
fn IdentifierMap::copy(self : IdentifierMap) -> IdentifierMap {
  let new_variable_map = {}
  for k, v in self._ {
    new_variable_map[k] = { ..v, from_current_block: false }
  }
  new_variable_map
}

///|
pub fn resolve(program : Program, counter : Counter) -> Program {
  let variable_map : IdentifierMap = {}
  let function_decls = []
  for function_def in program.function_decls {
    let function_def = variable_map.resolve_function_decl(function_def, counter)
    function_decls.push(function_def)
  }
  { function_decls, }
}

///|
fn resolve_function_decl(
  self : IdentifierMap,
  function_decl : FunctionDecl,
  counter : Counter
) -> FunctionDecl {
  if self._.get(function_decl.name) is Some(prev_entry) {
    if prev_entry.from_current_block && not(prev_entry.has_linkage) {
      @utils.die("Duplicate declaration")
    }
  }
  self._[function_decl.name] = {
    unique_name: function_decl.name,
    from_current_block: true,
    has_linkage: true,
  }
  let inner_map = self.copy()
  let params = []
  for param in function_decl.params {
    let unique_param_name = inner_map.resolve_var_decl_without_init(param, counter)
    params.push(unique_param_name)
  }
  let body = function_decl.body.map(inner_map.resolve_block(_, counter))
  { name: function_decl.name, params, body }
}

///|
fn resolve_var_decl_without_init(
  self : IdentifierMap,
  name : String,
  counter : Counter
) -> String {
  if self._.get(name) is Some(entry) && entry.from_current_block {
    @utils.die("Duplicate variable declaration for \{name}")
  }
  
  let new_name = counter.make_name_temporary(name)
  self._[name] = {
    unique_name: new_name,
    from_current_block: true,
    has_linkage: false,
  }
  new_name
}

///|
fn resolve_block(
  self : IdentifierMap,
  block : Block,
  counter : Counter
) -> Block {
  let body = []
  for block_item in block._ {
    body.push(self.resolve_block_item(block_item, counter))
  }
  body
}

///|
fn resolve_block_item(
  self : IdentifierMap,
  block_item : BlockItem,
  counter : Counter
) -> BlockItem {
  match block_item {
    S(stmt) => S(self.resovle_statement(stmt, counter))
    D(VarDecl(var_decl)) =>
      D(VarDecl(self.resolve_var_declaration(var_decl, counter)))
    D(FuncDecl({ body: Some(_), .. })) =>
      @utils.die("nested function definition are not allowed")
    D(FuncDecl(func_decl)) =>
      D(FuncDecl(self.resolve_function_decl(func_decl, counter)))
  }
}

///|
fn resolve_var_declaration(
  self : IdentifierMap,
  decl : VariableDecl,
  counter : Counter
) -> VariableDecl {
  let unique_name = self.resolve_var_decl_without_init(decl.name, counter)
  let init = match decl.init {
    Some(expr) => Some(self.resolve_expression(expr))
    None => None
  }
  { name: unique_name, init }
}

///|
fn resovle_statement(
  self : IdentifierMap,
  stmt : Stmt,
  counter : Counter
) -> Stmt {
  match stmt {
    Expression(e) => Expression(self.resolve_expression(e))
    Return(e) => Return(self.resolve_expression(e))
    If(cond, then, elze) => {
      let cond = self.resolve_expression(cond)
      let then = self.resovle_statement(then, counter)
      let elze = elze.map(self.resovle_statement(_, counter))
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
      let init = new_variable_map.resolve_for_init(init, counter)
      let cond = cond.map(new_variable_map.resolve_expression(_))
      let post = post.map(new_variable_map.resolve_expression(_))
      let body = new_variable_map.resovle_statement(body, counter)
      For(init, cond~, post~, body, label)
    }
  }
}

///|
fn resolve_expression(self : IdentifierMap, expr : Expr) -> Expr {
  match expr {
    Binary(op, left, right) =>
      Binary(op, self.resolve_expression(left), self.resolve_expression(right))
    Unary(op, expr) => Unary(op, self.resolve_expression(expr))
    Var(v) =>
      match self._.get(v) {
        Some({ unique_name: new_name, .. }) => Var(new_name)
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
    FunctionCall(func_name, args) => {
      if self._.get(func_name) is Some(new_func) {
        let new_args = []
        for arg in args {
          new_args.push(self.resolve_expression(arg))
        }
        return FunctionCall(new_func.unique_name, new_args)
      }
      @utils.die("Undeclared function!")
    }
  }
}

///|
fn resolve_for_init(
  self : IdentifierMap,
  init : @parser.ForInit,
  counter : @utils.Counter
) -> @parser.ForInit {
  match init {
    InitDecl(decl) => InitDecl(self.resolve_var_declaration(decl, counter))
    InitExpr(expr_opt) => InitExpr(expr_opt.map(self.resolve_expression(_)))
  }
}
