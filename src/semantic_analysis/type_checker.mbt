// typealias @symbols.SymbolTable
///|
typealias @types.Type

///|
priv type SymbolTable @symbols.SymbolTable

///|
pub fn typecheck(program : @parser.Program) -> @symbols.SymbolTable {
  let symbol_table : SymbolTable = @symbols.SymbolTable::new()
  for global_decl in program.decls {
    match global_decl {
      FuncDecl(func_decl) => symbol_table.check_function_decl(func_decl)
      VarDecl(var_decl) => symbol_table.check_file_scope_var_decl(var_decl)
    }
  }
  symbol_table._
}

///|
fn check_file_scope_var_decl(
  self : SymbolTable,
  decl : @parser.VariableDecl
) -> Unit {
  let current_init : @symbols.InitialValue = match decl.init {
    Some(Constant(i)) => Initial(i)
    None =>
      if decl.storage_class is Some(Extern) {
        NoInitializer
      } else {
        Tentative
      }
    _ => @utils.die("Non-constant initializer!")
  }
  let current_global = not(decl.storage_class is Some(Static))
  let (global, init) = if self._.get(decl.name) is Some(prev_decl) {
    if not(prev_decl.ty is TInt) {
      @utils.die("Function redeclared as variable")
    }
    if prev_decl.attrs is StaticAttr(prev_init, prev_global) {
      let global = if decl.storage_class is Some(Extern) {
        prev_global
      } else if current_global == prev_global {
        prev_global
      } else {
        @utils.die("Conflicting variable linkage")
      }
      let init = match (prev_init, current_init) {
        (Initial(_), Initial(_)) =>
          @utils.die("Conflicting global variable definition")
        (Initial(_), _) => prev_init
        (Tentative, Tentative | NoInitializer) => Tentative
        (_, Initial(_)) | (NoInitializer, _) => current_init
      }
      (global, init)
    } else {
      @utils.die(
        "Internal error, file-scope variable previously declared as local variable or function",
      )
    }
  } else {
    (current_global, current_init)
  }
  self._[decl.name] = { ty: TInt, attrs: StaticAttr(init, global) }
}

///|
fn check_function_decl(
  self : SymbolTable,
  function_decl : @parser.FunctionDecl
) -> Unit {
  let func_type : Type = TFuncType(function_decl.params.length())
  let has_body = function_decl.body is Some(_)
  let mut already_defined = false
  let mut global = not(function_decl.storage_class is Some(Static))
  if self._.get(function_decl.name) is Some(old_entry) {
    if func_type != old_entry.ty {
      @utils.die(
        "Incompatible function declarations, \{func_type}, \{old_entry.ty}",
      )
    }
    if old_entry.attrs is FuncAttr(defined=prev_defined, global=prev_global) {
      if prev_defined && has_body {
        @utils.die("Function \{function_decl.name} is defined more than once")
      }
      if prev_global && function_decl.storage_class is Some(Static) {
        @utils.die("Static function declaration follows non-static")
      }
      already_defined = prev_defined 
      global = prev_global
    }
  }
  self._[function_decl.name] = {
    ty: func_type,
    attrs: FuncAttr(defined=already_defined||has_body, global~),
    // has_defined: already_defined || has_body,
  }
  if has_body {
    for param in function_decl.params {
      self._[param] = { ty: TInt, attrs: LocalAttr }
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
    D(VarDecl(var_decl)) => self.check_local_variable_decl(var_decl)
  }
}

///|
fn check_local_variable_decl(
  self : SymbolTable,
  decl : @parser.VariableDecl
) -> Unit {
  match decl.storage_class {
    Some(Extern) => {
      if decl.init is Some(_) {
        @utils.die("Initializer on local extern declaration")
      }
      if self._.get(decl.name) is Some(entry) {
        if not(entry.ty is TInt) {
          @utils.die("Function redeclared as variable")
        }
      } else {
        self._[decl.name] = { ty: TInt, attrs: StaticAttr(NoInitializer, true) }
      }
    }
    Some(Static) => {
      let init : @symbols.InitialValue = match decl.init {
        Some(Constant(i)) => Initial(i)
        None => Initial(0)
        Some(_) =>
          @utils.die("non-constant initializer on local static variable")
      }
      self._[decl.name] = { ty: TInt, attrs: StaticAttr(init, false) }
    }
    None => {
      self._[decl.name] = { ty: TInt, attrs: LocalAttr }
      if decl.init is Some(init) {
        self.check_expression(init)
      }
    }
  }
}

///|
fn check_statement(self : SymbolTable, stmt : @parser.Stmt) -> Unit {
  match stmt {
    Compound(block) => self.check_block(block)
    For(init, cond~, post~, body, _) => {
      match init {
        InitExpr(Some(expr)) => self.check_expression(expr)
        InitDecl(var_decl) => self.check_local_variable_decl(var_decl)
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
      if self._.get(var) is Some(entry) && entry.ty is TFuncType(_) {
        @utils.die("Function name \{var} used as variable")
      }
    FunctionCall(f, args) => {
      let func_type = self._.get(f).unwrap().ty
      match func_type {
        TInt => @utils.die("Variable used as function name")
        TFuncType(argc) => {
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
