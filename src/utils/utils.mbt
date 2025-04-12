pub fn die[T](msg : String,loc~:SourceLoc=_) -> T {
  println("\{loc} \{msg}")
  panic()
}