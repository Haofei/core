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
/// `Rand` is a pseudo-random number generator (PRNG) that provides various
/// methods to generate random numbers of different types.
type Rand &Source

///|
/// The [Source] trait defines a method to generate random numbers.
pub(open) trait Source {
  next(Self) -> UInt64
}

///|
impl Source for @random_source.ChaCha8 with next(self : @random_source.ChaCha8) -> UInt64 {
  for {
    if self.next() is Some(x) {
      return x
    }
    self.refill()
  }
}

///|
/// Create a new random number generator with [seed].
/// @alert unsafe "Panic if seed is not 32 bytes long"
pub fn Rand::chacha8(
  seed~ : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456",
) -> Rand {
  if seed.length() != 32 {
    abort("seed must be 32 bytes long")
  }
  Rand(@random_source.ChaCha8::new(seed) as &Source)
}

///|
/// Create a new random number generator with [seed].
#deprecated("You may use `Rand::chacha8(seed~)` instead of `Rand::new(chacha8(seed~))")
pub fn chacha8(seed~ : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456") -> &Source {
  @random_source.ChaCha8::new(seed)
}

///|
/// Create a new random number generator with a given [Gen] source.
pub fn Rand::new(generator? : &Source) -> Rand {
  match generator {
    None => chacha8()
    Some(gen) => Rand(gen)
  }
}

///|
fn next(self : Rand) -> UInt64 {
  let Rand(s) = self
  s.next()
}

///|
test "next" {
  let r = new()
  let n = r.next()
  let exp = 13219109469176600229UL
  assert_eq(n, exp)
}

///|
/// [int] Return a non-negative pseudo-random 31-bit integer as an Int in the range [0, 2^31) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///             When limit is 0, the range is [0, 2^31).
pub fn int(self : Rand, limit~ : Int = 0) -> Int {
  if limit == 0 {
    // Range [0, 2^31)
    (self.next() >> 33).to_int()
  } else {
    self.uint(limit=limit.reinterpret_as_uint()).reinterpret_as_int()
  }
}

///|
/// [int64] returns a non-negative pseudo-random 63-bit integer as an Int64 in the range [0, 2^63)
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///            When limit is 0, the range is [0, 2^63).
pub fn int64(self : Rand, limit~ : Int64 = 0) -> Int64 {
  if limit == 0 {
    // range [0, 2^63)
    // Create a mask that keeps the lower 63 bits
    let mask : UInt64 = (1UL << 63) - 1UL
    return (self.next() & mask).reinterpret_as_int64()
  } else {
    self.uint64(limit=limit.reinterpret_as_uint64()).reinterpret_as_int64()
  }
}

///|
/// [uint] returns a non-negative pseudo-random 32-bit integer as a Uint in the range [0, 2^32) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///            When limit is 0, the range is [0, 2^32).
pub fn uint(self : Rand, limit~ : UInt = 0) -> UInt {
  if limit == 0 {
    // Range: [0, 2^32)
    return self.next().to_uint()
  }
  self.uint64(limit=limit.to_uint64()).to_uint()
}

///|
test "uint" {
  let r = new()
  let n = r.uint(limit=10U)
  inspect(n, content="7")
  let n = r.uint(limit=10U)
  inspect(n, content="0")
  let n = r.uint(limit=10U)
  inspect(n, content="5")
}

///|
/// [uint64] returns a non-negative pseudo-random 64-bit integer as a Uint64 in the range [0, 2^64) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///           When limit is 0, the range is [0, 2^64).
pub fn uint64(self : Rand, limit~ : UInt64 = 0) -> UInt64 {
  if limit == 0 {
    // Range: [0, 2^64)
    return self.next()
  } else if (limit & (limit - 1)) == 0 {
    // limit is a power of 2, mask to get the unbiased result.
    return self.next() & (limit - 1)
  }
  let mut r = umul128(self.next(), limit)
  if r.lo < limit {
    let thresh = limit.lnot() % limit
    while r.lo < thresh {
      r = umul128(self.next(), limit)
    }
  }
  r.hi
}

///|
test "UInt64" {
  let r = new()
  let n = r.uint64()
  let exp = 13219109469176600229UL
  assert_eq(n, exp)
  let r = new()
  let n = r.uint64(limit=10UL)
  inspect(n, content="7")
  let n = r.uint64(limit=10UL)
  inspect(n, content="0")
  let n = r.uint64(limit=10UL)
  inspect(n, content="5")
}

///|
/// [double] returns a pseudo-random 64-bit Double in the range [0.0, 1.0)
pub fn double(self : Rand) -> Double {
  Double::convert_uint64(self.next() << 11 >> 11) /
  Double::convert_uint64(1UL << 53)
}

///|
test "double" {
  let r = new()
  let n = r.double()
  inspect(n, content="0.615969772029264")
}

///|
/// [float] returns a pseudo-random 32-bit Float in the range [0.0, 1.0)
pub fn float(self : Rand) -> Float {
  (self.uint() << 8 >> 8).to_float() / (1U << 24).to_float()
}

///|
/// Generates a random positive `BigInt` with a specified number of bits.
///
/// Parameters:
///
/// * `rand` : A random number generator that implements the `Rand` trait.
/// * `bits` : The desired number of bits in the generated number.
///
/// Example:
///
/// ```moonbit
///   let rand = Rand::new()
///   let n = rand.bigint(8) // Generate random 8-bit number
///   inspect(n.bit_length() <= 8, content="true")
/// ```
pub fn bigint(self : Rand, bits : Int) -> @bigint.BigInt {
  let mod = bits % 8
  let len = if mod == 0 { bits / 8 } else { bits / 8 + 1 }
  let bytes = Bytes::makei(len, i => if i == 0 && mod != 0 {
    let mask = (1U << mod) - 1U
    (self.uint(limit=256) & mask).to_byte()
  } else {
    self.uint(limit=256).to_byte()
  })
  @bigint.BigInt::from_octets(bytes)
}

///|
test "bigint" {
  let r = new()
  inspect(r.bigint(1), content="1")
  inspect(r.bigint(3), content="4")
  inspect(r.bigint(7), content="124")
  inspect(r.bigint(8), content="214")
  inspect(r.bigint(32), content="2910404175")
  inspect(r.bigint(40), content="714745001576")
  inspect(r.bigint(64), content="13430064486797060338")
  inspect(r.bigint(128), content="251068071753473224445949321151725639522")
}

///|
#valtype
priv struct UInt128 {
  hi : UInt64
  lo : UInt64
}

///|
/// [umul128] returns the 128-bit product of x and y: (hi, lo) = x * y
/// with the product bits' upper half returned in hi and the lower
/// half returned in lo.
///
/// This function's execution time does not depend on the inputs.
fn umul128(a : UInt64, b : UInt64) -> UInt128 {
  let aLo = a & 0xffffffff
  let aHi = a >> 32
  let bLo = b & 0xffffffff
  let bHi = b >> 32
  let x = aLo * bLo
  let y = aHi * bLo + (x >> 32)
  let z = aLo * bHi + (y & 0xffffffff)
  let w = aHi * bHi + (y >> 32) + (z >> 32)
  { hi: w, lo: a * b }
}

///|
test "umul128" {
  let r = umul128(0x123456789ABCDEF0, 0xFEDCBA9876543210)
  assert_eq(r.hi, 1305938385386173474UL)
  assert_eq(r.lo, 2552847189736476416UL)
}

///|
test "umul128: handles small numbers correctly" {
  let r = umul128(1UL, 1UL)
  assert_eq(r.hi, 0UL)
  assert_eq(r.lo, 1UL)
}

///|
test "umul128: handles large numbers correctly" {
  let r = umul128(1UL, 0xFFFFFFFFFFFFFFFFUL)
  assert_eq(r.hi, 0UL)
  assert_eq(r.lo, 0xFFFFFFFFFFFFFFFFUL)
}

///|
test "umul128: handles zero correctly" {
  let r = umul128(0UL, 0UL)
  assert_eq(r.hi, 0UL)
  assert_eq(r.lo, 0UL)
}

///|
/// [shuffle] shuffles the first n elements of an array using the Fisher-Yates shuffle algorithm.
/// The limit should not be negative.
///
/// # Example
/// ```mbt
///   let r = Rand::new()
///   let a = [1, 2, 3, 4, 5]
///   r.shuffle(
///     a.length(),
///     (i : Int, j : Int) => {
///       let t = a[i]
///       a[i] = a[j]
///       a[j] = t
///     },
///   )
/// ```
pub fn shuffle(self : Rand, limit : Int, swap : (Int, Int) -> Unit) -> Unit {
  if limit < 0 {
    abort("Rand::shuffle: invalid argument limit")
  }
  for i = limit - 1; i > 0; i = i - 1 {
    let j = self.int(limit=i + 1)
    swap(i, j)
  }
}

///|
test "shuffle" {
  let r = new()
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i : Int, j : Int) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  inspect(a, content="[3, 5, 2, 1, 4]")
}
