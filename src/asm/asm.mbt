pub struct Program{
  function_def:FunctionDef
}derive(Show)
pub struct FunctionDef{
  name:String
  instructions:Array[Instruction]
}derive(Show)
pub enum Instruction{
  Mov(dst~:Operand,src~:Operand)
  Ret
}derive(Show)
pub enum Operand{
  Imm(Int)
  Register
}derive(Show)