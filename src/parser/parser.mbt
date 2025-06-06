///|
typealias @lexer.(TokenType, Token)

///|
typealias @types.Type

///|
priv type TokenStream @queue.T[Token] derive(Show)

///|
///|
priv trait Precedence {
  precedence(Self) -> Int
}

///|
impl Precedence for TokenType with precedence(self) {
  match self {
    Star | Slash | Percent => 50
    Plus | Hyphen => 45
    LessThan | GreaterThan | LessOrEqual | GreaterOrEqual => 35
    DoubleEqual | BangEqual => 30
    LogicAnd => 10
    LogicOr => 5
    QuestionMark => 3
    Equal | PlusEqual => 1
    _ => -1 // not a binary operator
  }
}

///|
pub fn parse(tokens : @queue.T[Token]) -> Program {
  let token_stream : TokenStream = tokens
  let function_decls = []
  while not(token_stream.peek().token_type is EOF) {
    let function_decl = token_stream.parse_decl()
    function_decls.push(function_decl)
  }
  token_stream.expect(EOF)
  { decls: function_decls }
}

///|
// fn parse_function_decl(self : TokenStream) -> FunctionDecl {
//   self.expect(KWInt)

//   { name, params, body }
// }

///|
fn parse_params(self : TokenStream) -> Array[String] {
  self.expect(LParen)
  let params = []
  match self.peek().token_type {
    KWVoid => {
      let _ = self.take()
      self.expect(RParen)
    }
    _ => {
      while true {
        self.expect(KWInt)
        let param = match self.take() {
          { token_type: Identifier(s), .. } => s
          tok => @utils.die("\{tok} is not a valid indentifier")
        }
        params.push(param)
        if not(self.peek().token_type is Comma) {
          break
        }
        let _ = self.take()

      }
      self.expect(RParen)
    }
  }
  params
}

///|
fn parse_block(self : TokenStream) -> Block {
  self.expect(LBrace)
  let body = []
  while not(self.peek().token_type is RBrace) {
    let block_item = self.parse_block_item()
    body.push(block_item)
  }
  self.expect(RBrace)
  body
}

///|
fn parse_block_item(self : TokenStream) -> BlockItem {
  if is_specifier(self.peek()) {
    D(self.parse_decl())
  } else {
    S(self.parse_statement())
  }
}

///|
fn is_specifier(token : Token) -> Bool {
  token.token_type is (KWInt | KWStatic | KWExtern)
}

///|
fn parse_decl(self : TokenStream) -> Decl {
  // let specifier_list = parse_specifier_list(self)
  let specifier_list = []
  while is_specifier(self.peek()) {
    specifier_list.push(self.take())
  }
  let (_, storage_class) = parse_type_and_storage_class(specifier_list)
  let name = self.parse_identifier()
  match self.peek().token_type {
    LParen => {
      let params = self.parse_params()
      let body = match self.peek().token_type {
        Semicolon => {
          let _ = self.take()
          None
        }
        _ => Some(self.parse_block())
      }
      FuncDecl({ name, storage_class, params, body })
    }
    tok => {
      let init = match tok {
        Equal => {
          let _ = self.take()
          Some(self.parse_expression(0))
        }
        _ => None
      }
      self.expect(Semicolon)
      VarDecl({ name, storage_class, init })
    }
  }
}

///|
fn parse_type_and_storage_class(
  specifier_list : Array[Token]
) -> (Type, StorageClass?) {
  let types = []
  let storage_classes = []
  for specifier in specifier_list {
    if specifier.token_type is KWInt {
      types.push(specifier)
    } else {
      storage_classes.push(specifier)
    }
  }
  // println(types)
  if types.length() != 1 {
    @utils.die("Invalid type specifier")
  }
  if storage_classes.length() > 1 {
    @utils.die("Invalid sotrage class")
  }
  let typ = Type::TInt
  let storage_class = if storage_classes.length() == 1 {
    Some(parse_storage_class(storage_classes[0]))
  } else {
    None
  }
  (typ, storage_class)
}

///|
fn parse_storage_class(storage_class : Token) -> StorageClass {
  match storage_class.token_type {
    KWStatic => Static
    KWExtern => Extern
    _ => @utils.die("\{storage_class} is not a storage_class")
  }
}

///|
fn parse_statement(self : TokenStream) -> Stmt {
  match self.peek().token_type {
    KWReturn => {
      let _ = self.take()
      let return_val = self.parse_expression(0)
      self.expect(Semicolon)
      Return(return_val)
    }
    KWIf => {
      let _ = self.take()
      self.expect(LParen)
      let cond = self.parse_expression(0)
      self.expect(RParen)
      let then = self.parse_statement()
      let elze = match self.peek().token_type {
        KWElse => {
          let _ = self.take()
          Some(self.parse_statement())
        }
        _ => None
      }
      If(cond, then, elze)
    }
    KWWhen => {
      let _ = self.take()
      self.expect(LBrace)
      // let mut stmt:Stmt=Null
      let cond = self.parse_expression(0)
      self.expect(RightArrow)
      let then = self.parse_statement()
      println(cond)
      println(then)
      // let mut stmt = If(cond,then,None)
      let elze_list = []
      while not(self.peek().token_type is RBrace) {
        if self.peek().token_type is KWElse {
          let _ = self.take()
          self.expect(RightArrow)
          elze_list.push((Constant(1), self.parse_statement()))
        } else {
          let cond = self.parse_expression(0)
          self.expect(RightArrow)
          let then = self.parse_statement()
          elze_list.push((cond, then))
        }
      }
      let _ = self.take()
      let mut elze = None
      for elze_stmt in elze_list.rev() {
        let (cond, then) = elze_stmt
        elze = Some(If(cond, then, elze))
      }
      If(cond, then, elze)
    }
    Semicolon => {
      let _ = self.take()
      Null
    }
    LBrace => Compound(self.parse_block())
    KWWhile => {
      let _ = self.take()
      self.expect(LParen)
      let cond = self.parse_expression(0)
      self.expect(RParen)
      let body = self.parse_statement()
      While(cond, body, "")
    }
    KWDo => {
      let _ = self.take()
      let body = self.parse_statement()
      self.expect(KWWhile)
      self.expect(LParen)
      let cond = self.parse_expression(0)
      self.expect(RParen)
      self.expect(Semicolon)
      DoWhile(body, cond, "")
    }
    KWFor => {
      let _ = self.take()
      self.expect(LParen)
      let for_init = self.parse_for_init()
      // self.expect(Semicolon)
      let cond = match self.peek().token_type {
        Semicolon => None
        _ => Some(self.parse_expression(0))
      }
      self.expect(Semicolon)
      let post = match self.peek().token_type {
        RParen => None
        _ => Some(self.parse_expression(0))
      }
      self.expect(RParen)
      let body = self.parse_statement()
      For(for_init, cond~, post~, body, "")
    }
    KWBreak => {
      let _ = self.take()
      self.expect(Semicolon)
      Break("")
    }
    KWContinue => {
      let _ = self.take()
      self.expect(Semicolon)
      Continue("")
    }
    _ => {
      let expr = self.parse_expression(0)
      self.expect(Semicolon)
      Expression(expr)
    }
  }
}

///|
fn parse_expression(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek().token_type
  while next_token.precedence() >= min_prec {
    match next_token {
      Equal => {
        let _ = self.take()
        let right = self.parse_expression(next_token.precedence())
        left = Assignment(left~, right~)
      }
      QuestionMark => {
        let _ = self.take()
        let then = self.parse_expression(0)
        self.expect(Colon)
        let elze = self.parse_expression(next_token.precedence())
        left = Conditional(cond=left, then~, elze~)
      }
      PlusEqual => {
        let _ = self.take()
        let right_expr = self.parse_expression(next_token.precedence())
        let right = Binary(Add, left, right_expr)
        left = Assignment(left~, right~)
      }
      _ => {
        let op = self.parse_binop()
        let right = self.parse_expression(next_token.precedence() + 1)
        left = Binary(op, left, right)
      }
    }
    next_token = self.peek().token_type
  }
  left
}

///|
fn parse_for_init(self : TokenStream) -> ForInit {
  if is_specifier(self.peek()) {
    match self.parse_decl() {
      VarDecl(vd) => {
        if vd.storage_class is Some(_){
          @utils.die("variable declaration in for loop can't have a storage_class")
        }
        InitDecl(vd)}
      _ => @utils.die("Found a function declaration in a for loop header")
    }
  } else {
    let init = match self.peek().token_type {
      Semicolon => InitExpr(None)
      _ => InitExpr(Some(self.parse_expression(0)))
    }
    self.expect(Semicolon)
    init
  }
}

///|
fn parse_factor(self : TokenStream) -> Expr {
  let token = self.peek()
  match token.token_type {
    Constant(i) => {
      let _ = self.take()
      Constant(i)
    }
    Bang | Hyphen | Tilde => { // is unary opeartor
      let op = self.parse_unop()
      let inner_expr = self.parse_factor()
      Unary(op, inner_expr)
    }
    Identifier(name) => {
      let _ = self.take()
      match self.peek().token_type {
        LParen => self.parse_function_call(name)
        _ => Var(name)
      }
      // Var(name)
    }
    LParen => {
      let _ = self.take()
      let inner_expr = self.parse_expression(0)
      self.expect(RParen)
      inner_expr
    }
    _ => @utils.die("\{token}, Malformed expression")
  }
}

///|
fn parse_function_call(self : TokenStream, name : String) -> Expr {
  let _ = self.take() // LParen
  let arguments = []
  // f(a,b,c)
  if not(self.peek().token_type is RParen) {
    arguments.push(self.parse_expression(0))
  }
  while not(self.peek().token_type is RParen) {
    self.expect(Comma)
    arguments.push(self.parse_expression(0))
  }
  let _ = self.take()
  FunctionCall(name, arguments)
}

///|
fn parse_unop(self : TokenStream) -> UnaryOp {
  match self.take().token_type {
    Hyphen => Negate
    Tilde => Complement
    Bang => Not
    tok => @utils.die("\{tok} is not a valid unary operator")
  }
}

///|
fn parse_binop(self : TokenStream) -> BinaryOp {
  match self.take().token_type {
    Plus => Add
    Hyphen => Sub
    Star => Mul
    Slash => Div
    Percent => Rem
    LogicAnd => And
    LogicOr => Or
    DoubleEqual => Equal
    BangEqual => NotEqual
    LessThan => LessThan
    GreaterThan => GreaterThan
    LessOrEqual => LessOrEqual
    GreaterOrEqual => GreaterOrEqual
    tok => @utils.die("\{tok} is not a valid binary operator")
  }
}

///|
fn peek(self : TokenStream) -> Token {
  match self._.peek() {
    Some({ token_type: Comment(_), .. }) => {
      let _ = self.take()
      self.peek()
    }
    Some(tok) => tok
    None => @utils.die("End of Stream")
  }
}

///|
fn npeek(self : TokenStream, n : Int) -> Array[TokenType] {
  if n <= 0 {
    @utils.die("Can't peek \{n} token(s)")
  }
  let tokens = []
  let mut cnt = 0
  for token in self._.iter() {
    tokens.push(token.token_type)
    cnt += 1
    if cnt == n {
      break
    }
  }
  if cnt < n {
    @utils.die("Can't peek \{n} token(s), end of stream")
  }
  tokens
}

///|
fn take(self : TokenStream) -> Token {
  match self._.pop() {
    Some(tok) => tok
    None => @utils.die("End of Stream")
  }
}

///|
fn parse_identifier(self : TokenStream) -> String {
  match self.take() {
    { token_type: Identifier(name), .. } => name
    tok => @utils.die("\{tok} is Not a vaild funciton")
  }
}

///|
fn expect(self : TokenStream, expected : TokenType) -> Unit {
  let actual = self.take().token_type
  if actual != expected {
    @utils.die("Expected:\{expected}, actual:\{actual}, Syntax error")
  }
}

///|
test {
  let content =
    #| int main(void){
    #|    int a = 3;
    #|    int b = a;
    #|    int c;
    #|    return a+b;
    #|}
  let tokens = @lexer.lex(content)
  let ast = parse(tokens)
  inspect!(
    ast,
    content=
      #|{function_decls: [{name: "main", params: [], body: Some(Block([D(VarDecl({name: "a", init: Some(Constant(3))})), D(VarDecl({name: "b", init: Some(Var("a"))})), D(VarDecl({name: "c", init: None})), S(Return(Binary(Add, Var("a"), Var("b"))))]))}]}
    ,
  )
}

///|
test "Assignment" {
  let content =
    #| int main(void){
    #|    int a = b = 3;
    #|    return a+b;
    #|}
  let tokens = @lexer.lex(content)
  let ast = parse(tokens)
  inspect!(
    ast,
    content=
      #|{function_decls: [{name: "main", params: [], body: Some(Block([D(VarDecl({name: "a", init: Some(Assignment(left=Var("b"), right=Constant(3)))})), S(Return(Binary(Add, Var("a"), Var("b"))))]))}]}
    ,
  )
}

///|
test "redundate_parens" {
  let content =
    #|int main(void)
    #|{
    #|return -((((10))));
    #|}
  let tokens = @lexer.lex(content)
  let ast = parse(tokens)
  inspect!(
    ast,
    content=
      #|{function_decls: [{name: "main", params: [], body: Some(Block([S(Return(Unary(Negate, Constant(10))))]))}]}
    ,
  )
}

///|
test {
  let content = "1+2*3+4"
  let tokens : TokenStream = @lexer.lex(content)
  let ast = tokens.parse_expression(0)
  inspect!(
    ast,
    content="Binary(Add, Binary(Add, Constant(1), Binary(Mul, Constant(2), Constant(3))), Constant(4))",
  )
}

///|
test "expr 2" {
  let content = " ~2 + 3"
  let tokens : TokenStream = @lexer.lex(content)
  let ast = tokens.parse_expression(0)
  inspect!(
    ast,
    content="Binary(Add, Unary(Complement, Constant(2)), Constant(3))",
  )
}

///|
test "if-else" {
  let content =
    #|if (a == 3) return a; else b = 8;
  let tokens : TokenStream = @lexer.lex(content)
  let ast = tokens.parse_statement()
  inspect!(
    ast,
    content=
      #|If(Binary(Equal, Var("a"), Constant(3)), Return(Var("a")), Some(Expression(Assignment(left=Var("b"), right=Constant(8)))))
    ,
  )
}

///|
test "for" {
  let content =
    #|for (; ;);
  let tokens : TokenStream = @lexer.lex(content)
  let ast = tokens.parse_statement()
  inspect!(
    ast,
    content=
      #|For(InitExpr(None), cond=None, post=None, Null, "")
    ,
  )
}

///|
test "expr conditional" {
  let content = "a?1:b?2:3"
  let tokens : TokenStream = @lexer.lex(content)
  let ast = tokens.parse_expression(0)
  inspect!(
    ast,
    content=
      #|Conditional(cond=Var("a"), then=Constant(1), elze=Conditional(cond=Var("b"), then=Constant(2), elze=Constant(3)))
    ,
  )
}
