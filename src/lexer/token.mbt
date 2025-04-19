///|
pub(all) enum TokenType {
  Identifier(String)
  Constant(Int)
  //  keywords 
  KWInt
  KWVoid
  KWReturn
  KWIf
  KWElse
  KWDo
  KWWhile
  KWFor
  KWBreak
  KWContinue
  KWStatic
  KWExtern
  // punctuation 
  LParen
  RParen
  LBrace
  RBrace
  Hyphen
  DoubleHyphen
  Tilde
  Semicolon
  Plus
  Star
  Slash
  Percent
  Equal
  Bang // ! 
  LogicAnd // && 
  LogicOr //|| 
  DoubleEqual // == 
  BangEqual // != 
  LessThan
  GreaterThan
  LessOrEqual
  GreaterOrEqual
  QuestionMark
  Colon
  Comma
  EOF
  Invalid
  Comment(String)
} derive(Show, Eq)

///|
pub struct Token {
  token_type : TokenType
  position : Position
} derive(Show)

///|
struct Position {
  row : Int
  col : Int
}
///|
// pub fn to_string(self : Position) -> String {
//   "\{self.row}:\{self.col}"
// }

///|
impl Show for Position with to_string(self) -> String {
  "\{self.row}:\{self.col}"
}

///|
impl Show for Position with output(self, logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
// pub fn precdence(self : Token) -> Int {
//   match self {
//     Equal => 1
//     QuestionMark => 3
//     LogicOr => 5
//     LogicAnd => 10
//     DoubleEqual | BangEqual => 30
//     LessThan | GreaterThan | LessOrEqual | GreaterOrEqual => 35
//     Plus | Hyphen => 45
//     Star | Slash | Percent => 50
//     tok => @utils.die("\{tok} is not a Binary operator")
//   }
// }
