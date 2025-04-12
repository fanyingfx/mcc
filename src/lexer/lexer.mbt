struct Lexer {
  len:Int
  content:String
  mut pos:Int
  mut ch:Char?
}

fn Lexer::new(content:String)->Lexer{
  let lexer = {len:content.length(),content,pos:-1,ch:None}
  lexer.advance_char()
  lexer
}
fn peek_char(self:Lexer)->Char?{
  if self.pos+1 >= self.len{
    None
  }else{
    Some(self.content.unsafe_char_at(self.pos+1))
  }
}
fn eat_while(self:Lexer,predicate:(Char?)->Bool)->String{
  let start = self.pos
  while predicate(self.peek_char()){
    self.advance_char()
  }
  self.content.substring(start~,end=self.pos+1)
}
fn advance_char(self:Lexer)->Unit{
  self.ch = self.peek_char()
  self.pos += 1
}
fn skip_whitespace(self:Lexer)->Unit{
  while self.ch is Some(ch) && ch.is_ascii_whitespace(){
    self.advance_char()
  }
}
fn make_int(self:Lexer)->Token{

  let int_str = self.eat_while(fn {
    Some('0'..='9') => true
    _ => false
  })
  let v_int = try {@strconv.parse_int!(int_str)}
  catch{
    _ => @utils.die("Parse int Error, \{self.ch}, pos:\{self.pos}")
  }
  Constant(v_int)

}
let keywords:Map[String,Token]=
 {
  "int": KWInt,
  "void": KWVoid,
  "return": KWReturn,
  "if": KWIf,
  "else": KWElse,
  "do": KWDo,
  "while": KWWhile,
  "for": KWFor,
  "break": KWBreak,
  "continue": KWContinue,
  "static": KWStatic,
  "extern": KWExtern,
}
fn make_ident_or_keyword(self:Lexer)->Token{
  let idstr = self.eat_while( fn {
    Some(   'a'..='z'|'A'..='Z'|'_'|'0'..='9')=>true
    _ => false
  })
  match keywords[idstr]{
    None => Identifier(idstr)
    Some(kw)=>kw
  }

}
fn next_token(self:Lexer)->Token{
  self.skip_whitespace()
  let tok:Token = match self.ch{
    Some(c)=>{
      match c{
       '0'..='9'=> self.make_int()
       'a'..='z'|'A'..='Z'|'_'=>self.make_ident_or_keyword()
          '(' => LParen
        ')' => RParen
        '{' => LBrace
        '}' => RBrace
        ';' => Semicolon
        '~' => Tilde
        '+' => Plus
        '-' => Hyphen
        '*' => Star
        '/' => Slash
        '%' => Percent
        '?' => QuestionMark
        ':' => Colon
        ',' => Comma
        _ =>@utils.die("Can not match next_token")
      }
    }
    None => EOF
  }
  self.advance_char()
  tok
}

pub fn lex(content:String)->@queue.T[Token]{
  let lexer = Lexer::new(content)
  let tokens = @queue.new()
  while true{
    match lexer.next_token(){
      EOF => break
      tok => tokens.push(tok)
    }
  }
  tokens.push(EOF)
  tokens

}

test "simple main"{

  let content = 
  #| int main(void){
  #|    return 2;
  #|}
  
inspect!(lex(content), content=
  #|@queue.of([KWInt, Identifier("main"), LParen, KWVoid, RParen, LBrace, KWReturn, Constant(2), Semicolon, RBrace, EOF])
)


}
test "painc"{
  let _= lex("&")
}
