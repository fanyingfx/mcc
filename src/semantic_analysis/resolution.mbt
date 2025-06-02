///|
typealias @parser.(
  Decl,
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
  from_current_scope : Bool
  has_linkage : Bool
}

///|
fn IdentifierMap::copy(self : IdentifierMap) -> IdentifierMap {
  let new_variable_map = {}
  for k, v in self._ {
    new_variable_map[k] = { ..v, from_current_scope: false }
  }
  new_variable_map
}

///|
pub fn resolve(program : Program, counter : Counter) -> Program {
  let variable_map : IdentifierMap = {}
  let decls = []
  for decl in program.decls {
    let decl : Decl = match decl {
      FuncDecl(func_decl) =>
        FuncDecl(variable_map.resolve_function_decl(func_decl, counter))
      VarDecl(var_decl) =>
        VarDecl(variable_map.resovle_file_scope_variable_decl(var_decl))
    }
    decls.push(decl)
  }
  { decls, }
}

// ///|
// fn resolve_global_decl(
//   self : IdentifierMap,
//   decl : Decl,
//   counter : Counter
// ) -> Decl {
//   match decl {
//     FuncDecl(func_decl) =>
//       FuncDecl(self.resolve_function_decl(func_decl, counter))
//     VarDecl(var_decl) =>
//       VarDecl(self.resovle_file_scope_variable_decl(var_decl))
//   }
// }

///|
fn resovle_file_scope_variable_decl(
  self : IdentifierMap,
  decl : VariableDecl
  // counter : Counter
) -> VariableDecl {
  self._[decl.name] = {
    unique_name: decl.name,
    from_current_scope: true,
    has_linkage: true,
  }
  decl
}

///|
fn resolve_function_decl(
  self : IdentifierMap,
  function_decl : FunctionDecl,
  counter : Counter
) -> FunctionDecl {
  if self._.get(function_decl.name) is Some(prev_entry) {
    if prev_entry.from_current_scope && not(prev_entry.has_linkage) {
      @utils.die("Duplicate declaration")
    }
  }
  self._[function_decl.name] = {
    unique_name: function_decl.name,
    from_current_scope: true,
    has_linkage: true,
  }
  let inner_map = self.copy()
  let params = []
  for param in function_decl.params {
    let unique_param_name = inner_map.resolve_local_var_decl_helper(
      { name: param, init: None, storage_class: None },
      counter,
    )
    params.push(unique_param_name)
  }
  let body = function_decl.body.map(inner_map.resolve_block(_, counter))
  {
    name: function_decl.name,
    params,
    body,
    storage_class: function_decl.storage_class,
  }
}

///|
fn resolve_local_var_decl(
  self : IdentifierMap,
  decl : VariableDecl,
  counter : Counter
) -> VariableDecl {
  let name = self.resolve_local_var_decl_helper(decl, counter)
  let init = decl.init.map(self.resolve_expression(_))
  { name, init, storage_class: decl.storage_class }
}

///|
fn resolve_local_var_decl_helper(
  self : IdentifierMap,
  decl : VariableDecl,
  counter : Counter
) -> String {
  if self._.get(decl.name) is Some(entry) && entry.from_current_scope {
    if not(entry.has_linkage && decl.storage_class is Some(Extern)) {
      @utils.die("Conflicting local declarations")
    }
  }
  let entry = if decl.storage_class is Some(Extern) {
    { unique_name: decl.name, from_current_scope: true, has_linkage: true }
  } else {
    let new_name = counter.make_name_temporary(decl.name)
    { unique_name: new_name, from_current_scope: true, has_linkage: false }
  }
  self._[decl.name] = entry
  entry.unique_name
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
      D(VarDecl(self.resolve_local_var_decl(var_decl, counter)))
    D(FuncDecl({ body: Some(_), .. })) =>
      @utils.die("nested function definition are not allowed")
    D(FuncDecl({ storage_class:Some(Static), .. })) =>
      @utils.die("static keyword not allowed on local function declarations")
    D(FuncDecl(func_decl)) =>
      D(FuncDecl(self.resolve_function_decl(func_decl, counter)))
  }
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
    Var(v) => {
      let new_var : Expr = match self._.get(v) {
        Some({ unique_name, .. }) => Var(unique_name)
        None => @utils.die("Undeclared variable '\{v}'")
      }
      new_var
    }
    Constant(i) => Constant(i)
    Assignment(left~, right~) => {
      if not(left is Var(_)) {
        @utils.die("Invalid lvalue!")
      }
      let new_left = self.resolve_expression(left)
      Assignment(left=new_left, right=self.resolve_expression(right))
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
    InitDecl(decl) => InitDecl(self.resolve_local_var_decl(decl, counter))
    InitExpr(expr_opt) => InitExpr(expr_opt.map(self.resolve_expression(_)))
  }
}
