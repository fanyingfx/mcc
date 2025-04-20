///|
pub(all) struct Program {
  function_def : FunctionDef
} derive(Show)

///|
pub(all) struct FunctionDef {
  name : String
  body : Stmt
} derive(Show)

///|
pub(all) enum Stmt {
  Return(Expr)
} derive(Show)

///|
pub(all) enum Expr {
  Constant(Int)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
} derive(Show)

///|
pub(all) enum UnaryOp {
  Complement
  Negate
} derive(Show)

///|
pub enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
} derive(Show)
