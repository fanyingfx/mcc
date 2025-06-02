///|
pub fn validate(
  ast : @parser.Program,
  counter : @utils.Counter
) -> (@parser.Program, @symbols.SymbolTable) {
  let resolved_ast = resolve(ast, counter)
  let symbol_table = typecheck(resolved_ast)
  let validated_ast = loop_label(resolved_ast, counter)
  (validated_ast, symbol_table)
}
