///|
pub(all) enum Token {
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
