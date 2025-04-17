///|
struct Program {
  function_def : FunctionDef
} derive(Show)

///|
struct FunctionDef {
  name : String
  body : Array[Instruction]
} derive(Show)

///|
enum Instruction {
  Return(Val)
  Unary(UnaryOp, dst~ : Val, src~ : Val)
} derive(Show)

///|
enum Val {
  Constant(Int)
  Var(String)
} derive(Show)

///|
enum UnaryOp {
  Complement
  Negate
} derive(Show)
