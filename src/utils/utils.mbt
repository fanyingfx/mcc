///|
pub fn die[T](msg : String, loc~ : SourceLoc = _) -> T {
  println("\{loc} \{msg}")
  panic()
}

///|
pub fn log[T : Show](msg : T, loc~ : SourceLoc = _) -> Unit {
  println("\{loc} \{msg}")
}

///|
// let counter : Ref[Int] = { val: 0 }

pub struct Counter{
  mut val:Int
}

pub fn Counter::new()->Counter{
  {val:0}
}

///| reset counter for testing
/// only can use in test
// pub fn reset_counter() -> Unit {
//   counter.val = 0
// }

///|
pub fn Counter::make_label(self:Counter,label : String) -> String {
  let name = label + self.val.to_string()
  self.val += 1
  name
}

///|
pub fn make_temporary(self:Counter) -> String {
  let temp = "tmp.\{self.val}"
  self.val += 1
  temp
}
