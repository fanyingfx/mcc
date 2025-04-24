///|
pub struct Program {
  function_def : FunctionDef
} derive(Show)

///|
pub struct FunctionDef {
  name : String
  body : Stmt
} derive(Show)

///|
pub enum Stmt {
  Return(Expr)
} derive(Show)

///|
pub enum Expr {
  Constant(Int)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
} derive(Show)

///|
pub enum UnaryOp {
  Complement
  Negate
  Not
} derive(Show)

///|
pub enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
  And
  Or
  Equal
  NotEqual
  LessThan
  LessOrEqual
  GreaterThan
  GreaterOrEqual
} derive(Show)
