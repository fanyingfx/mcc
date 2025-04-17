///|
pub fn die[T](msg : String, loc~ : SourceLoc = _) -> T {
  println("\{loc} \{msg}")
  panic()
}

///|
let counter : Ref[Int] = { val: 0 }

///| reset counter for testing
/// only can use in test
pub fn reset_counter()->Unit {
  counter.val = 0
}

///|
pub fn make_temporary() -> String {
  let temp = "tmp.\{counter.val}"
  counter.val += 1
  temp
}
