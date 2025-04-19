///|
typealias @lexer.(TokenType, Token)

///|
priv type TokenStream @queue.T[Token] derive(Show)

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
    {token_type:Identifier(name),..} => name
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
  let return_val = self.parse_expr()
  self.expect(Semicolon)
  Return(return_val)
}

///|
fn parse_expr(self : TokenStream) -> Expr {
  match self.peek().token_type {
    Constant(i) => {
      let _ = self.take()
      Constant(i)
    }
    Hyphen | Tilde => {
      let op = self.parse_unop()
      let inner_expr = self.parse_expr()
      Unary(op, inner_expr)
    }
    LParen => {
      let _ = self.take()
      let inner_expr = self.parse_expr()
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
    tok => @utils.die("\{tok} is not a valid unary operator")
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
