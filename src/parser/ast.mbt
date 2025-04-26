///|
pub(all) struct Program {
  function_def : FunctionDef
} derive(Show)

///|
pub(all) struct FunctionDef {
  name : String
  body : Array[BlockItem]
} derive(Show)

///|
pub(all) enum BlockItem {
  S(Stmt)
  D(Decl)
} derive(Show)

///|
pub(all) struct Decl {
  name : String
  init : Expr?
} derive(Show)

///|
pub(all) enum Stmt {
  Return(Expr)
  Expression(Expr)
  Null
} derive(Show)

///|
pub(all) enum Expr {
  Constant(Int)
  Var(String)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
  Assignment(left~ : Expr, right~ : Expr)
} derive(Show)

///|
pub(all) enum UnaryOp {
  Complement
  Negate
  Not
} derive(Show)

///|
pub(all) enum BinaryOp {
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
