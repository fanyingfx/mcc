///|
struct Setting {
  filename : String
  basename : String
  stage : Stage
} derive(Show)

///|
fn Setting::get_setting() -> Setting {
  let args = @sys.get_cli_args()
  if not(args.length() is (3 | 4)) {
    @utils.die("Wrong number args")
  }
  let filename = args[2]
  if not(filename.has_suffix(".i") || filename.has_suffix(".c")) {
    @utils.die("\{filename} is not a c file")
  }
  let stage = if args.length() == 4 { args[3] } else { "--compile" }
  let stage_str = stage.trim_start("-")
  let stage = match stage_str {
    "lex" => Lex
    "parse" => Parse
    "tacky" => Tacky
    "codegen" => CodeGen
    "compile" => Compile
    _ => @utils.die("\{stage_str} is not a valid stage")
  }
  let basename = filename.trim_end("ci").trim_end(".")
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
  Tacky
  CodeGen
  Compile
} derive(Show, Eq)

///|
fn main {
  let setting = Setting::get_setting()
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
  let tacky = @tacky.emit_tacky(ast)
  if setting.stage is Tacky {
    println("End in \{setting.stage}")
    return
  }
  let asm = @backend.compile(tacky)
  if setting.stage is CodeGen {
    println("End in \{setting.stage}")
    return
  }
  let asm_str = @emit.emit(asm)
  // println(setting.asm_file())
  @fs.write_string_to_file?(setting.asm_file(), asm_str).unwrap()
}
