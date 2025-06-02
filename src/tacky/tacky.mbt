///|
pub struct Program {
  toplevels : Array[TopLevel]
} derive(Show)

pub enum TopLevel{
  Function(FunctionDecl)
  StaticVariable(name~:String,global~:Bool,init~:Int)
}derive(Show)
///|
pub struct FunctionDecl {
  name : String
  global:Bool
  params:Array[String]
  body : Array[Instruction]
}

///|
impl Show for FunctionDecl with to_string(self) {
  let body = self.body.map(fn(inst) { "  " +inst.to_string() }).join("\n")
  "\n\{self.name}:\n\{body}"
}

///|
impl Show for FunctionDecl with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub enum Instruction {
  Return(Val)
  Unary(UnaryOp, dst~ : Val, src~ : Val)
  Binary(BinaryOp, dst~ : Val, src1~ : Val, src2~ : Val)
  Copy(dst~ : Val, src~ : Val)
  Jump(String)
  JumpIfZero(Val, String)
  JumpIfNotZero(Val, String)
  Label(String)
  FuncCall(String,Array[Val],Val)
}

///|
pub impl Show for Instruction with to_string(self) {
  match self {
    JumpIfNotZero(v, label) => "jnz \{v} \{label}"
    JumpIfZero(v, label) => "jz \{v} \{label}"
    Jump(label) => "jmp \{label}"
    Copy(dst~, src~) => "\{dst} = \{src}"
    Binary(op, dst~, src1~, src2~) => "\{dst} = \{src1} \{op} \{src2}"
    Unary(op, dst~, src~) => "\{dst} = \{op}\{src}"
    Return(v) => "return \{v}"
    Label(label) => "\{label}:"
    FuncCall(fname,args,v)=>{
      let args_string = args.map(Val::to_string).join(",")
      "\{v} = \{fname} (\{args_string})"}
  }
}

///|
pub impl Show for Instruction with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub enum Val {
  Constant(Int)
  Var(String)
} derive(Show)

///|
pub enum UnaryOp {
  Complement
  Negate
  Not
}

///|
pub impl Show for UnaryOp with to_string(self) {
  match self {
    Negate => "-"
    Complement => "~"
    Not => "!"
  }
}

///|
pub impl Show for UnaryOp with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Rem
  Equal
  NotEqual
  LessThan
  LessOrEqual
  GreaterThan
  GreaterOrEqual
}

///|
pub impl Show for BinaryOp with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for BinaryOp with to_string(self) {
  match self {
    GreaterThan => ">"
    LessOrEqual => "<="
    LessThan => "<"
    NotEqual => "!="
    Equal => "=="
    Rem => "%"
    Div => "/"
    Mul => "*"
    Sub => "-"
    Add => "+"
    GreaterOrEqual => ">="
  }
}

///|
