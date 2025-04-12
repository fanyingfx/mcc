///|
typealias @lexer.Token

///|
priv type TokenStream @queue.T[Token] derive(Show)

pub fn parse(tokens:@queue.T[Token])->Program{
  let token_stream:TokenStream = tokens
  let func = token_stream.parse_func_def()
  token_stream.expect(EOF)
  {function_def: func,}
}
fn parse_func_def(self:TokenStream)->FunctionDef{
  self.expect(KWInt)
  let name = match self.take(){
    Identifier(name)=>name
    _ => @utils.die("Not a vaild funciton")
  }
  self.expect(LParen)
  self.expect(KWVoid)
  self.expect(RParen)
  self.expect(LBrace)

  let stmt = self.parse_statement()
  self.expect(RBrace)
  {name,body:stmt}
}
///|
fn parse_statement(self : TokenStream) -> Stmt {
  self.expect(KWReturn)

  let return_val = self.parse_expr()
  self.expect(Semicolon)
  Return(return_val)
}

fn parse_expr(self:TokenStream)->Expr{
  match self.take(){
    Constant(i) => Constant(i)
    _ =>@utils.die("not a valid int")
  }
}
///|
fn peek(self : TokenStream) -> Token {
  match self._.peek() {
    Some(tok) => tok
    None => @utils.die("End of Stream")
  }
}

fn take(self:TokenStream)->Token{
  match self._.pop(){
    Some(tok)=>tok
    None => @utils.die("End of Stream")
  }
}

///|
fn expect(self : TokenStream, expected : Token) -> Unit {
  let actual = self.take()
  if actual != expected{
    @utils.die("Syntax error")
  }
}

test{
  let content = 
  #| int main(void){
  #|    return 3;
  #|}
  let tokens = @lexer.lex(content)
  let ast = parse(tokens)
  inspect!(ast, content=
    #|{func: {name: "main", body: Return(Constant(3))}}
  )
}
