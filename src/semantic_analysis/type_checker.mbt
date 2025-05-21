///|
priv enum Type {
  Int
  FuncType(Int)
} derive(Show, Eq)

///|
type SymbolTable Map[String, SymbolEntry]

///|
priv struct SymbolEntry {
  ty : Type
  has_defined : Bool
}

///|
// fn SymbolTable::copy(self : SymbolTable) -> SymbolTable {
//   let new_table = {}
//   for k, v in self._ {
//     new_table[k] = v
//   }
//   new_table
// }

///|
pub fn typecheck(program : @parser.Program) -> SymbolTable {
  let symbol_table : SymbolTable = {}
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
  if self._.get(function_decl.name) is Some(entry) && entry.ty is FuncType(_) {
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
  self._[function_decl.name] = {
    ty: func_type,
    has_defined: already_defined || has_body,
  }
  if has_body {
    // let new_symbol_table = self.copy()
    for param in function_decl.params {
      self._[param] = { ty: Int, has_defined: false }
    }
    self.check_block(function_decl.body.unwrap())
  }
}

///|
fn check_block(self : SymbolTable, block : @parser.Block) -> Unit {
  // let new_symbole_table = self.copy()
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
  self._[var_decl.name] = { ty: Int, has_defined: false }
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

      // if left is Var(name) {
      //   if self._.get(name) is Some(entry) && entry.ty is Int {
      //     // println("left:\{left}, right:\{right}")
      //     self.check_expression(right)
      //     return ()
      //   }
      //   @utils.die("assign to a function")
      // }
      // @utils.die("assign to a rvalue")
    }
    Binary(_, left, right) => {
      self.check_expression(left)
      self.check_expression(right)
    }
    Unary(_, expr) => self.check_expression(expr)
    Var(var) =>{
      if self._.get(var) is Some(entry) && entry.ty is FuncType(_) {
        @utils.die("Function name \{var} used as variable")
      }
    }
    Constant(_) => ()
    FunctionCall(f, args) => {
      let func_type = self._.get(f).unwrap().ty
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
  }
}
