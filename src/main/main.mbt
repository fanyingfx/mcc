///|
struct Setting {
  filename : String
  basename : String
  stage : Stage
} derive(Show)

///|
fn Setting::get_setting() -> Setting {
  let args = @sys.get_cli_args()
  if not(args.length() is (2 | 3)) {
    @utils.die("Wrong number args")
  }
  let filename = args[1]
  if not(filename.has_suffix(".i") || filename.has_suffix(".c")) {
    @utils.die("\{filename} is not a c file")
  }
  let stage = if args.length() == 3 { args[2] } else { "--compile" }
  let stage_str = stage.trim_start("-")
  let stage = match stage_str {
    "lex" => Lex
    "parse" => Parse
    "validate" => Validate
    "tacky" => Tacky
    "codegen" => CodeGen
    "compile" => Compile
    _ => @utils.die("\{stage_str} is not a valid stage")
  }
  let basename = filename.trim_end("ci").trim_end(".").to_string()
  { filename, basename, stage }
}

///|
fn asm_file(self : Setting) -> String {
  self.basename + ".asm"
}

///|
enum Stage {
  Lex
  Parse
  Validate
  Tacky
  CodeGen
  Compile
} derive(Show, Eq)

///|
fn main {
  let setting = Setting::get_setting()
  // let setting = Setting::{filename:"examples2/declaration_only.i",basename:"examples2/declaration_only",stage:Compile}
  // println(setting)
  let content = @fs.read_file_to_string?(setting.filename).unwrap()
  let tokens = @lexer.lex(content)
  if setting.stage is Lex {
    println("End in \{setting.stage}")
    return
  }
  let ast = @parser.parse(tokens)
  if setting.stage is Parse {
    println("End in \{setting.stage}")
    return
  }
  // println(ast)
  let counter = @utils.Counter::new()
  let (validated_ast, symbol_table) = @semantic_analysis.validate(ast, counter)
  if setting.stage is Validate {
    println("End in \{setting.stage}")
    return
  }
  // println(validated_ast)
  let tacky = @tacky.emit_tacky(validated_ast,symbol_table, counter)
  println(tacky)
  if setting.stage is Tacky {
    println("End in \{setting.stage}")
    return
  }
  let asm = @backend.compile(tacky,symbol_table)
  // println(asm)
  if setting.stage is CodeGen {
    println("End in \{setting.stage}")
    return
  }
  let asm_str = @emit.emit(asm, symbol_table)
  // println(setting.asm_file())
  @fs.write_string_to_file?(setting.asm_file(), asm_str).unwrap()
}
