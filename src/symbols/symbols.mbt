///|
typealias @types.Type

///|
pub(all) enum IdentifierAttr {
  FuncAttr(defined~ : Bool, global~ : Bool)
  StaticAttr(InitialValue, Bool)
  LocalAttr
} derive(Show)

///|
pub(all) enum InitialValue {
  Tentative
  Initial(Int)
  NoInitializer
} derive(Show)

///|

///|
pub type SymbolTable Map[String, SymbolEntry] derive(Show)

///|
pub fn SymbolTable::new() -> SymbolTable {
  return {}
}

///|
pub fn SymbolTable::set(
  self : SymbolTable,
  name : String,
  entry : SymbolEntry
) -> Unit {
  self._.set(name, entry)
}

///|
pub fn SymbolTable::get(self : SymbolTable, name : String) -> SymbolEntry? {
  self._.get(name)
}

///|
pub fn SymbolTable::op_set(
  self : SymbolTable,
  name : String,
  value : SymbolEntry
) -> Unit {
  self.set(name, value)
}

///|
pub fn is_function(self : SymbolTable, name : String) -> Bool {
  if self.get(name) is Some(entry) {
    match entry.attrs {
      FuncAttr(_) => true
      _ => false
    }
  } else {
    false
  }
}

///|
pub fn SymbolTable::is_global(self : SymbolTable, name : String) -> Bool {
  if self.get(name) is Some(entry) {
    match entry.attrs {
      StaticAttr(_, global) => global
      FuncAttr(defined=_, global~) => global
      LocalAttr => false
    }
  } else {
    false
  }
}

///|
pub fn SymbolTable::is_static(self : SymbolTable, name : String) -> Bool {
  if self.get(name) is Some(entry) {
    match entry.attrs {
      StaticAttr(_) => true
      LocalAttr => false
      FuncAttr(_) => @utils.die("functions don't have sotrage duration")
    }
  } else {
    false
  }
}

///|
pub(all) struct SymbolEntry {
  ty : Type
  // has_defined : Bool
  attrs : IdentifierAttr
} derive(Show)
