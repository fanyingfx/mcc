///|
pub(all) struct Program {
  function_def : FunctionDef
} derive(Show)

///|
pub(all) struct FunctionDef {
  name : String
  body : Block
} derive(Show)

///|
pub(all) enum BlockItem {
  S(Stmt)
  D(Decl)
} derive(Show)

///|
pub(all) type Block Array[BlockItem] derive(Show)

///|
pub(all) struct Decl {
  name : String
  init : Expr?
} derive(Show)

///|
pub(all) enum Stmt {
  Return(Expr)
  Expression(Expr)
  If(Expr, Stmt, Stmt?)
  Break(String)
  Continue(String)
  While(Expr,Stmt,String)
  DoWhile(Stmt,Expr,String)
  For(ForInit,cond~:Expr?,post~:Expr?,Stmt,String)
  Compound(Block)
  Null
} derive(Show)

pub(all) enum ForInit{
  InitDecl(Decl)
  InitExpr(Expr?)
}derive(Show)

///|
pub(all) enum Expr {
  Constant(Int)
  Var(String)
  Unary(UnaryOp, Expr)
  Binary(BinaryOp, Expr, Expr)
  Assignment(left~ : Expr, right~ : Expr)
  Conditional(cond~ : Expr, then~ : Expr, elze~ : Expr)
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
