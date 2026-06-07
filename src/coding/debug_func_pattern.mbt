test "debug is_function_pattern for (8,13)" {
  let plan = new_plan(1, L)
  init_grid(plan)

  let x = 8
  let y = 13
  let size = 21

  println("\nChecking (8, 13):")
  println("  size = " + size.to_string())

  // Check each condition
  let cond1 = (x <= 8 && y <= 8)
  println("  (x <= 8 && y <= 8) = " + cond1.to_string())

  let cond2 = (x >= size - 8 && y <= 8)
  println("  (x >= size - 8 && y <= 8) = (x >= 13 && y <= 8) = " + cond2.to_string())

  let cond3 = (x <= 8 && y >= size - 8)
  println("  (x <= 8 && y >= size - 8) = (x <= 8 && y >= 13) = " + cond3.to_string())

  let cond4 = (x == 6 || y == 6)
  println("  (x == 6 || y == 6) = " + cond4.to_string())

  let cond5 = (x == 8 && y == size - 8)
  println("  (x == 8 && y == size - 8) = (x == 8 && y == 13) = " + cond5.to_string())

  let cond6_x = (x == 8 && (y <= 8 || y >= size - 7))
  println("  x == 8 && (y <= 8 || y >= size - 7) = (8 == 8 && (13 <= 8 || 13 >= 14)) = " + cond6_x.to_string())

  let cond6_y = (y == 8 && (x <= 8 || x >= size - 7))
  println("  y == 8 && (x <= 8 || x >= size - 7) = (13 == 8 && ...) = " + cond6_y.to_string())

  let result = is_function_pattern(plan, x, y)
  println("\n  Final result: " + result.to_string())
}
