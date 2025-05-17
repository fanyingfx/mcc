///|
pub struct Program {
  function_defs : Array[FunctionDef]
} derive(Show)

///|
pub struct FunctionDef {
  name : String
  instructions : Array[Instruction]
} derive(Show)

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
  R10
  DX
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