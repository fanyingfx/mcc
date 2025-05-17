///|
pub(all) struct Program {
  function_decls : Array[FunctionDecl]
} derive(Show)


///|
pub(all) enum BlockItem {
  S(Stmt)
  D(Decl)
} derive(Show)

///|
pub(all) type Block Array[BlockItem] derive(Show)
pub (all) enum Decl{
  FuncDecl(FunctionDecl)
  VarDecl(VariableDecl)
}derive(Show)
pub(all) struct FunctionDecl{
  name:String
  params:Array[String]
  body:Block?
}derive(Show)

///|
pub(all) struct VariableDecl {
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
  InitDecl(VariableDecl)
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
  FunctionCall(String,Array[Expr])
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
