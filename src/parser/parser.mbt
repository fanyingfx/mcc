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
    tok => @utils.die("\{tok} is not supported yet")
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
  let name = match self.take() {
    { token_type: Identifier(name), .. } => name
    tok => @utils.die("\{tok} is Not a vaild funciton")
  }
  self.expect(LParen)
  self.expect(KWVoid)
  self.expect(RParen)
  self.expect(LBrace)
  let stmt = self.parse_statement()
  self.expect(RBrace)
  { name, body: stmt }
}

///|
fn parse_statement(self : TokenStream) -> Stmt {
  self.expect(KWReturn)
  let return_val = self.parse_expr(0)
  self.expect(Semicolon)
  Return(return_val)
}

///|
fn parse_expr(self : TokenStream, min_prec : Int) -> Expr {
  let mut left = self.parse_factor()
  let mut next_token = self.peek().token_type
  while is_binary_op(next_token) && next_token.precedence() >= min_prec {
    let op = self.parse_binop()
    let right = self.parse_expr(next_token.precedence() + 1)
    left = Binary(op, left, right)
    next_token = self.peek().token_type
  }
  left
}

///|
fn is_binary_op(token_type : TokenType) -> Bool {
  token_type
  is (Plus
  | Hyphen
  | Star
  | Slash
  | Percent
  | LogicAnd
  | LogicOr
  | DoubleEqual
  | BangEqual
  | LessThan
  | GreaterThan
  | LessOrEqual
  | GreaterOrEqual)
}

///|
fn parse_factor(self : TokenStream) -> Expr {
  match self.peek().token_type {
    Constant(i) => {
      let _ = self.take()
      Constant(i)
    }
    Bang | Hyphen | Tilde=> { // is unary opeartor
      let op = self.parse_unop()
      let inner_expr = self.parse_factor()
      Unary(op, inner_expr)
    }
    LParen => {
      let _ = self.take()
      let inner_expr = self.parse_expr(0)
      self.expect(RParen)
      inner_expr
    }
    tok => @utils.die("\{tok}, Malformed expression")
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
    #|    return 3;
    #|}
  let tokens = @lexer.lex(content)
  let ast = parse(tokens)
  inspect!(
    ast,
    content=
      #|{function_def: {name: "main", body: Return(Constant(3))}}
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
      #|{function_def: {name: "main", body: Return(Unary(Negate, Constant(10)))}}
    ,
  )
}

///|
test {
  let content = "1+2*3+4"
  let tokens = @lexer.lex(content)
  let ast = parse_expr(tokens, 0)
  inspect!(
    ast,
    content="Binary(Add, Binary(Add, Constant(1), Binary(Mul, Constant(2), Constant(3))), Constant(4))",
  )
}

///|
test "expr 2" {
  let content = " ~2 + 3"
  let tokens = @lexer.lex(content)
  let ast = parse_expr(tokens, 0)
  inspect!(
    ast,
    content="Binary(Add, Unary(Complement, Constant(2)), Constant(3))",
  )
}
