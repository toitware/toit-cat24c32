// Copyright (C) 2022 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

/**
Driver for the CAT24C32 EEPROM.
*/

import binary
import math
import i2c

/// The start I2C address is 0x50, but alts go up to 0x57.
I2C-ADDRESS     ::= 0x50

/**
Driver for the CAT24C32 EEPROM.
*/
class Cat24c32:

  /** Size in bytes. */
  static SIZE ::= 4096

  static MAX-WRITE-OFFLINE-US_ ::= 5_000
  static PAGE-SIZE_ ::= 32
  static PAGE-MASK_ ::= ~0x1F

  device_ /i2c.Device ::= ?
  last-write-us_ /int := -MAX-WRITE-OFFLINE-US_

  constructor .device_:

  /**
  Reads a single byte at address $at.
  The address must satisfy 0 <= $at < $SIZE.
  */
  operator[] at/int -> int:
    return (read at --size=1)[0]

  /**
  Writes a single byte $new-value at address $at.
  The address must satisfy 0 <= $at < $SIZE.
  */
  operator[]= at/int new-value/int -> none:
    write at #[new-value]

  /**
  Reads $size bytes starting at $address.
  The address must satisfy 0 <= $address <= $SIZE - $size.
  */
  read address/int --size=1 -> ByteArray:
    if size < 0: throw "INVALID_ARGUMENT"
    if not 0 <= address << address + size <= SIZE: throw "OUT_OF_RANGE"
    if size == 0: return #[]
    return try_: return device_.read-address #[ address >> 8, address & 0xFF ] size

  /**
  Writes the given $bytes starting at $address.
  The address must satisfy 0 <= $address <= $SIZE - ($bytes).size.
  */
  write address/int bytes/ByteArray -> none:
    if not 0 <= address << address + bytes.size <= SIZE: throw "OUT_OF_RANGE"
    if bytes.size == 0: return
    // The device is split into pages of 32 bytes.
    // Never write across page boundaries. The device would just wrap around.
    if address & PAGE-MASK_ == (address + bytes.size - 1) & PAGE-MASK_:
      write-page_ address bytes
      return

    // The address bits of the first page.
    first-page-offset := address - (address & PAGE-MASK_)
    first-page-bytes := PAGE-SIZE_ - first-page-offset
    List.chunk-up 0 bytes.size first-page-bytes PAGE-SIZE_: | from to |
      write-page_ (address + from) bytes[from..to]

  /**
  Writes the given $bytes to the $address.
  The $bytes must only write to one page.
  */
  write-page_ address/int bytes/ByteArray -> none:
    assert: address & PAGE-MASK_ == (address + bytes.size - 1) & PAGE-MASK_
    try_:
      device_.write-address #[ address >> 8, address & 0xFF ] bytes
      last-write-us_ = Time.monotonic-us

  try_ [block]:
    // After a write the device is offline for up to MAX_WRITE_OFFLINE_MS_.
    // Try the operation, but be ok if it fails.
    now := Time.monotonic-us
    while last-write-us_ + MAX-WRITE-OFFLINE-US_ >= now:
      catch: return block.call
      sleep --ms=1
    // If the device should have written, just do the operation.
    return block.call

