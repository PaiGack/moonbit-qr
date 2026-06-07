test "check column 8 function pattern status" {
  let plan = new_plan(1, L)
  init_grid(plan)

  println("\nColumn 8 function pattern status (size=21):")
  for y = 0; y < 21; y = y + 1 {
    let is_func = is_function_pattern(plan, 8, y)
    let status = if is_func { "FUNC" } else { "DATA" }
    println("  row " + y.to_string() + ": " + status)
  }

  println("\nExpected:")
  println("  rows 0-8: FUNC (format info)")
  println("  rows 9-13: DATA (data region)")
  println("  rows 14-20: FUNC (format info)")
}
