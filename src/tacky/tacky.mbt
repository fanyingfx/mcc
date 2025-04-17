///|
pub struct Program {
  function_def : FunctionDef
} derive(Show)

///|
pub struct FunctionDef {
  name : String
  body : Array[Instruction]
} derive(Show)

///|
pub enum Instruction {
  Return(Val)
  Unary(UnaryOp, dst~ : Val, src~ : Val)
} derive(Show)

///|
pub enum Val {
  Constant(Int)
  Var(String)
} derive(Show)

///|
pub enum UnaryOp {
  Complement
  Negate
} derive(Show)
