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
struct RangeImpl[T] {
  lo : T
  hi : T
} derive(Show, ToJson)

///|
// pub
// priv
// default to abstract
trait Range {
  range(Self, Self) -> RangeImpl[Self]
}

///|
impl Range for Int with range(lo, hi) {
  { lo, hi }
}

///|
impl Range for String with range(lo, hi) {
  { lo, hi }
}

///|
fn[T : Range] my_range(lo : T, hi : T) -> RangeImpl[T] {
  T::range(lo, hi)
}
// Note when use trait to encode overloading:
// 1. the trait must be exposed to users
//    ideas: can we have a feature called final trait?

///|
test {
  @json.inspect(my_range(1, 10), content={ "lo": 1, "hi": 10 })
  @json.inspect(my_range("a", "z"), content={ "lo": "a", "hi": "z" })
}

///|
fn labeld_break(xss : Array[Array[Double]]) -> Double? {
  let mut threshold = 0.0
  mylabel~: for xs in xss {
    for x in xs {
      threshold += x
      if threshold > 10.0 {
        break mylabel~ Some(threshold)
      }
    }
  } else {
    None
  }
}

///|
test "labeld_break/empty" {
  let xss : Array[Array[Double]] = []
  inspect(labeld_break(xss), content="None")
}

///|
test "labeld_break/sum_under_threshold" {
  let xss = [[1.0, 2.0], [3.0, 4.0]]
  inspect(labeld_break(xss), content="None")
}

///|
test "labeld_break/cross_threshold" {
  let xss = [[3.0, 4.0], [5.0, 6.0]]
  inspect(labeld_break(xss), content="Some(12)")
}

///|
test "try!" {
  let a = "hello world"
  fn hello() noraise {
    try! a[1:]
  }

  inspect(hello(), content="ello world")
}
