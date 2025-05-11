///|
typealias @lexer.(TokenType, Token)

///|
priv type TokenStream @queue.T[Token] derive(Show)

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
  let func = token_stream.parse_func_def()
  token_stream.expect(EOF)
  { function_def: func }
}

///|
fn parse_func_def(self : TokenStream) -> FunctionDef {
  self.expect(KWInt)
  let name = self.parse_identifier()
  self.expect(LParen)
  self.expect(KWVoid)
  self.expect(RParen)
  // self.expect(LBrace)
  let body = self.parse_block()
  { name, body }
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
  match self.peek().token_type {
    KWInt => D(self.parse_declaration())
    _ => S(self.parse_statement())
  }
}

///|
fn parse_declaration(self : TokenStream) -> Decl {
  let _ = self.take()
  let name = self.parse_identifier()
  let init = match self.peek().token_type {
    Equal => {
      let _ = self.take()
      Some(self.parse_expression(0))
    }
    _ => None
  }
  self.expect(Semicolon)
  { name, init }
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
      self.expect(Semicolon)
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
  let for_init = match self.peek().token_type {
    KWInt => {
      let _ = self.take()
      let name = self.parse_identifier()
      let init = match self.peek().token_type {
        Equal => {
          let _ = self.take()
          Some(self.parse_expression(0))
        }
        _ => None
      }
      InitDecl({ name, init })
    }
    Semicolon => InitExpr(None)
    _ => InitExpr(Some(self.parse_expression(0)))
  }
  for_init
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
      Var(name)
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
      #|{function_def: {name: "main", body: Block([D({name: "a", init: Some(Constant(3))}), D({name: "b", init: Some(Var("a"))}), D({name: "c", init: None}), S(Return(Binary(Add, Var("a"), Var("b"))))])}}
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
      #|{function_def: {name: "main", body: Block([D({name: "a", init: Some(Assignment(left=Var("b"), right=Constant(3)))}), S(Return(Binary(Add, Var("a"), Var("b"))))])}}
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
      #|{function_def: {name: "main", body: Block([S(Return(Unary(Negate, Constant(10))))])}}
    ,
  )
}

///|
test {
  let content = "1+2*3+4"
  let tokens = @lexer.lex(content)
  let ast = parse_expression(tokens, 0)
  inspect!(
    ast,
    content="Binary(Add, Binary(Add, Constant(1), Binary(Mul, Constant(2), Constant(3))), Constant(4))",
  )
}

///|
test "expr 2" {
  let content = " ~2 + 3"
  let tokens = @lexer.lex(content)
  let ast = parse_expression(tokens, 0)
  inspect!(
    ast,
    content="Binary(Add, Unary(Complement, Constant(2)), Constant(3))",
  )
}

///|
test "if-else" {
  let content =
    #|if (a == 3) return a; else b = 8;
  let tokens = @lexer.lex(content)
  let ast = parse_statement(tokens)
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
  let tokens = @lexer.lex(content)
  let ast = parse_statement(tokens)
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
  let tokens = @lexer.lex(content)
  let ast = parse_expression(tokens, 0)
  inspect!(
    ast,
    content=
      #|Conditional(cond=Var("a"), then=Constant(1), elze=Conditional(cond=Var("b"), then=Constant(2), elze=Constant(3)))
    ,
  )
}
