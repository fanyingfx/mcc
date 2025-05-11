///|
priv struct Lexer {
  len : Int
  content : String
  mut pos : Int
  mut row : Int
  mut col : Int
  mut ch : Char?
}

///|
fn Lexer::new(content : String) -> Lexer {
  let lexer = {
    len: content.length(),
    content,
    pos: -1,
    ch: None,
    row: 1,
    col: 1,
  }
  lexer.advance_char()
  lexer
}

///|
fn peek_char(self : Lexer) -> Char? {
  if self.pos + 1 >= self.len {
    None
  } else {
    Some(self.content.unsafe_char_at(self.pos + 1))
  }
}

///|
fn eat_while(self : Lexer, predicate : (Char) -> Bool) -> String {
  let start = self.pos
  while self.peek_char() is Some(ch) && predicate(ch) {
    if self.peek_char() is None {
      break
    }
    self.advance_char()
  }
  self.content.substring(start~, end=self.pos + 1)
}

///|
fn advance_char(self : Lexer) -> Unit {
  if self.ch is Some('\n') {
    self.row += 1
    self.col = 1
  }
  if self.peek_char() is Some(ch) {
    self.ch = Some(ch)
    self.col += 1
    self.pos += 1
  } else {
    self.ch = None
  }
}

///|
fn skip_whitespace(self : Lexer) -> Unit {
  while self.ch is Some(ch) && ch.is_ascii_whitespace() {
    self.advance_char()
  }
}

///|
///|
fn make_int(self : Lexer) -> TokenType {
  let int_str = self.eat_while(fn {
    '0'..='9' => true
    'a'..='z' | 'A'..='Z' => panic()
    _ => false
  })
  let v_int = try {
    @strconv.parse_int!(int_str)
  } catch {
    _ => @utils.die("Parse int Error, \{self.ch}, pos:\{self.pos}")
  }
  Constant(v_int)
}

///|
let keywords : Map[String, TokenType] = {
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

///|
fn make_ident_or_keyword(self : Lexer) -> TokenType {
  let idstr = self.eat_while(fn {
    'a'..='z' | 'A'..='Z' | '_' | '0'..='9' => true
    _ => false
  })
  match keywords.get(idstr) {
    None => Identifier(idstr)
    Some(kw) => kw
  }
}

///|
fn match_next_char(self : Lexer, ch : Char) -> Bool {
  match self.peek_char() {
    Some(c) if c == ch => {
      self.advance_char()
      true
    }
    _ => false
  }
}

///|
fn multiple_comment(self : Lexer) -> TokenType {
  let start_offset = self.pos
  while self.peek_char() is Some(ch) && not(self.ch is Some('*') && ch == '/') {
    self.advance_char()
  }
  self.advance_char()
  let mut end_offset = if self.peek_char() is None {
    self.pos
  } else {
    self.pos + 1
  }
  if end_offset >= 2 &&
    self.content.charcode_at(end_offset - 1) == '/' &&
    self.content.charcode_at(end_offset - 2) == '*' {
    end_offset = end_offset - 2
  }
  Comment(self.content.view(start_offset~, end_offset~))
}

///|
fn next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  let position : Position = { row: self.row, col: self.col }
  let token_type : TokenType = match self.ch {
    Some(c) =>
      match c {
        '0'..='9' => self.make_int()
        'a'..='z' | 'A'..='Z' | '_' => self.make_ident_or_keyword()
        '(' => LParen
        ')' => RParen
        '{' => LBrace
        '}' => RBrace
        ';' => Semicolon
        '~' => Tilde
        '+' => if self.match_next_char('=') { PlusEqual } else { Plus }
        '-' => if self.match_next_char('-') { DoubleHyphen } else { Hyphen }
        '*' => Star
        '/' =>
          if self.match_next_char('/') {
            let comment = self.eat_while(fn { c => c != '\n' })
            Comment(comment)
          } else if self.match_next_char('*') {
            self.multiple_comment()
          } else {
            Slash
          }
        '%' => Percent
        '?' => QuestionMark
        ':' => Colon
        ',' => Comma
        '!' => if self.match_next_char('=') { BangEqual } else { Bang }
        '=' => if self.match_next_char('=') { DoubleEqual } else { Equal }
        '<' => if self.match_next_char('=') { LessOrEqual } else { LessThan }
        '>' =>
          if self.match_next_char('=') {
            GreaterOrEqual
          } else {
            GreaterThan
          }
        '&' =>
          if self.match_next_char('&') {
            LogicAnd
          } else {
            @utils.die("'&' not suppoorted yet")
          }
        '|' =>
          if self.match_next_char('|') {
            LogicOr
          } else {
            @utils.die("'|' not supported yet")
          }
        _ => @utils.die("Unknown token '\{c}'")
      }
    None => EOF
  }
  self.advance_char()
  { token_type, position }
}

///|
pub fn lex(content : String) -> @queue.T[Token] {
  let lexer = Lexer::new(content)
  let tokens = @queue.new()
  while true {
    match lexer.next_token() {
      { token_type: EOF, .. } as eof => {
        tokens.push(eof)
        break
      }
      tok => tokens.push(tok)
    }
  }
  tokens
}

///|
test "simple main" {
  let content =
    #| int main(void){
    #|    return 2;
    #|}
  inspect!(
    lex(content),
    content=
      #|@queue.of([{token_type: KWInt, position: 1:3}, {token_type: Identifier("main"), position: 1:7}, {token_type: LParen, position: 1:11}, {token_type: KWVoid, position: 1:12}, {token_type: RParen, position: 1:16}, {token_type: LBrace, position: 1:17}, {token_type: KWReturn, position: 2:6}, {token_type: Constant(2), position: 2:13}, {token_type: Semicolon, position: 2:14}, {token_type: RBrace, position: 3:2}, {token_type: EOF, position: 3:2}])
    ,
  )
}

///|
test "simple main" {
  let content =
    #| int main(void){
    #|    return 100;
    #|}
  inspect!(
    lex(content),
    content=
      #|@queue.of([{token_type: KWInt, position: 1:3}, {token_type: Identifier("main"), position: 1:7}, {token_type: LParen, position: 1:11}, {token_type: KWVoid, position: 1:12}, {token_type: RParen, position: 1:16}, {token_type: LBrace, position: 1:17}, {token_type: KWReturn, position: 2:6}, {token_type: Constant(100), position: 2:13}, {token_type: Semicolon, position: 2:16}, {token_type: RBrace, position: 3:2}, {token_type: EOF, position: 3:2}])
    ,
  )
}

///|
test "comment" {
  inspect!(
    lex("// 1234"),
    content=
      #|@queue.of([{token_type: Comment("/ 1234"), position: 1:2}, {token_type: EOF, position: 1:8}])
    ,
  )
  let multiple_comment =
    #|1;/*dsdfdsfds
    #|fsdfsdfds
    #|sdfsdfsdf
  inspect!(
    lex(multiple_comment),
    content=
      #|@queue.of([{token_type: Constant(1), position: 1:2}, {token_type: Semicolon, position: 1:3}, {token_type: Comment("*dsdfdsfds\nfsdfsdfds\nsdfsdfsd"), position: 1:4}, {token_type: EOF, position: 3:10}])
    ,
  )
  let multiple_comment =
    #|1;/*dsdfdsfds
    #|fsdfsdfds
    #|sdfsdfsdf*/
  inspect!(
    lex(multiple_comment),
    content=
      #|@queue.of([{token_type: Constant(1), position: 1:2}, {token_type: Semicolon, position: 1:3}, {token_type: Comment("*dsdfdsfds\nfsdfsdfds\nsdfsdfsdf*"), position: 1:4}, {token_type: EOF, position: 3:12}])
    ,
  )
}

///|
test "panic" {
  let _ = lex("&")

}

///|
test "panic invalid" {
  let content =
    #|  int main(void)
    #|{
    #|   return @b;
    #|}
  let _ = lex(content)

}
