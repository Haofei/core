// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Check if two floating point numbers are equal within a small epsilon.
///
/// Only used for testing when the result can't be precisely represented
/// by IEEE 754 double.
fn check(x : Double, y : Double) -> Bool {
  (x - y).abs() < 1.0e-15
}

///|
test "mod" {
  // normal numbers
  inspect(check(7.5 % 2.3, 0.6), content="true")
  inspect(check(-3.6 % 1.4, -0.8), content="true")
  inspect(check(0.7 % 0.2, 0.1), content="true")
  inspect(5.75 % 5.75, content="0")
  inspect(15.25 % 4.5, content="1.75")
  inspect(-8.4 % 3.2, content="-2")
  inspect(8.0 % 4.0, content="0")
  inspect(15.0 % 3.0, content="0")
  // subnormal numbers
  inspect(5.0e-324 % 5.0e-324, content="0")
  inspect(0.5 % 1.5e-323, content="1e-323")
  inspect(4.0e-310 % 3.0e-310, content="1e-310")
  // inf
  inspect(1.0 % @double.infinity, content="1")
  assert_true((@double.infinity % @double.infinity).is_nan())
  assert_true((@double.infinity % 1).is_nan())
  // division by zero
  assert_true((1.0 % 0).is_nan())
  assert_true((1.0 % -0).is_nan())
  // nan
  assert_true((@double.not_a_number % 1.0).is_nan())
  assert_true((1.0 % @double.not_a_number).is_nan())
}
