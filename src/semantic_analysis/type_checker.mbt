///|
enum Type {
  Int
  FuncType(Int)
} derive(Show, Eq)

///|
pub fn is_function(ty : Type) -> Bool {
  ty is FuncType(_)
}

///|
pub type SymbolTable Map[String, SymbolEntry] derive(Show)

///|
fn SymbolTable::new() -> SymbolTable {
  return {}
}

///|
fn SymbolTable::set(
  self : SymbolTable,
  name : String,
  entry : SymbolEntry
) -> Unit {
  self._.set(name, entry)
}

///|
fn SymbolTable::get(self : SymbolTable, name : String) -> SymbolEntry? {
  self._.get(name)
}

///|
fn SymbolTable::op_set(
  self : SymbolTable,
  name : String,
  value : SymbolEntry
) -> Unit {
  self.set(name, value)
}

///|
pub struct SymbolEntry {
  ty : Type
  has_defined : Bool
}derive(Show)

///|
pub fn typecheck(program : @parser.Program) -> SymbolTable {
  let symbol_table = SymbolTable::new()
  for function_decl in program.function_decls {
    symbol_table.check_function_decl(function_decl)
  }
  symbol_table
}

///|
fn check_function_decl(
  self : SymbolTable,
  function_decl : @parser.FunctionDecl
) -> Unit {
  let func_type = FuncType(function_decl.params.length())
  let has_body = function_decl.body is Some(_)
  let mut already_defined = false
  if self.get(function_decl.name) is Some(entry)  {
    if func_type != entry.ty {
      @utils.die(
        "Incompatible function declarations, \{func_type}, \{entry.ty}",
      )
    }
    if entry.has_defined && has_body {
      @utils.die("Function \{function_decl.name} is defined more than once")
    }
    already_defined = entry.has_defined 
  }
  self[function_decl.name] = { ty: func_type, has_defined: already_defined || has_body}
  if has_body {
    for param in function_decl.params {
      self[param] = { ty: Int, has_defined: false }
    }
    self.check_block(function_decl.body.unwrap())
  }
}

///|
fn check_block(self : SymbolTable, block : @parser.Block) -> Unit {
  for item in block._ {
    self.check_block_item(item)
  }
}

///|
fn check_block_item(self : SymbolTable, block_item : @parser.BlockItem) -> Unit {
  match block_item {
    S(stmt) => self.check_statement(stmt)
    D(FuncDecl(func_decl)) => self.check_function_decl(func_decl)
    D(VarDecl(var_decl)) => self.check_variable_decl(var_decl)
  }
}

///|
fn check_variable_decl(
  self : SymbolTable,
  var_decl : @parser.VariableDecl
) -> Unit {
  self[var_decl.name] = { ty: Int, has_defined: false }
  if var_decl.init is Some(expr) {
    self.check_expression(expr)
  }
}

///|
fn check_statement(self : SymbolTable, stmt : @parser.Stmt) -> Unit {
  match stmt {
    Compound(block) => self.check_block(block)
    For(init, cond~, post~, body, _) => {
      match init {
        InitExpr(Some(expr)) => self.check_expression(expr)
        InitDecl(var_decl) => self.check_variable_decl(var_decl)
        InitExpr(None) => ()
      }
      if cond is Some(expr) {
        self.check_expression(expr)
      }
      if post is Some(expr) {
        self.check_expression(expr)
      }
      self.check_statement(body)
    }
    DoWhile(body, cond, _) => {
      self.check_expression(cond)
      self.check_statement(body)
    }
    While(cond, body, _) => {
      self.check_expression(cond)
      self.check_statement(body)
    }
    If(cond, then, elze) => {
      self.check_expression(cond)
      self.check_statement(then)
      if elze is Some(stmt) {
        self.check_statement(stmt)
      }
    }
    Expression(e) => self.check_expression(e)
    Return(e) => self.check_expression(e)
    Null | Break(_) | Continue(_) => ()
  }
}

///|
fn check_expression(self : SymbolTable, expr : @parser.Expr) -> Unit {
  match expr {
    Conditional(cond~, then~, elze~) => {
      self.check_expression(cond)
      self.check_expression(then)
      self.check_expression(elze)
    }
    Assignment(right~, left~) => {
      self.check_expression(left)
      self.check_expression(right)
    }
    Binary(_, left, right) => {
      self.check_expression(left)
      self.check_expression(right)
    }
    Unary(_, expr) => self.check_expression(expr)
    Var(var) =>
      if self.get(var) is Some(entry) && entry.ty is FuncType(_) {
        @utils.die("Function name \{var} used as variable")
      }
    FunctionCall(f, args) => {
      let func_type = self.get(f).unwrap().ty
      match func_type {
        Int => @utils.die("Variable used as function name")
        FuncType(argc) => {
          if argc != args.length() {
            @utils.die("Function called with the wrong number of arguments")
          }
          for arg in args {
            self.check_expression(arg)
          }
        }
      }
    }
    Constant(_) => ()
  }
}
