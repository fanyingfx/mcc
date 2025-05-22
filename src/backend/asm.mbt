///|
pub struct Program {
  function_defs : Array[FunctionDef]
} derive(Show)

///|
pub struct FunctionDef {
  name : String
  instructions : Array[Instruction]
} 
impl Show for FunctionDef with to_string(self) {
  let body = self.instructions.map(fn(inst) { "  " +inst.to_string() }).join("\n")
  "\n\{self.name}:\n\{body}"
}

///|
impl Show for FunctionDef with output(self, logger) {
  logger.write_string(self.to_string())
}
///|
pub enum Instruction {
  Mov(dst~ : Operand, src~ : Operand)
  Unary(UnaryOp, Operand)
  Binary(BinaryOp,Operand,Operand)
  Cmp(Operand,Operand)
  Idiv(Operand)
  Cdq
  Jmp(String)
  JmpCC(CondCode,String)
  SetCC(CondCode,Operand)
  Label(String)
  AllocateStack(Int)
  DeallocateStack(Int)
  Push(Operand)
  Call(String)
  Ret
} derive(Show)

///|
pub enum UnaryOp {
  Neg
  Not
} derive(Show)
pub enum BinaryOp{
  Add
  Sub
  Mul
}derive(Show)
///|
pub enum Operand {
  Imm(Int)
  Reg(Reg)
  Pseudo(String)
  Stack(Int)
} derive(Show)

///|
pub enum Reg {
  AX
  CX
  DX
  DI
  SI
  R8
  R9
  R10
  R11
} derive(Show)

pub enum CondCode{
  E
  NE
  G
  GE
  L
  LE
}derive(Show)