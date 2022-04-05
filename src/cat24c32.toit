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
I2C_ADDRESS     ::= 0x50

/**
Driver for the CAT24C32 EEPROM.
*/
class Cat24c32:

  /** Size in bytes. */
  static SIZE ::= 4096

  static MAX_WRITE_OFFLINE_US_ ::= 5_000
  static PAGE_SIZE_ ::= 32
  static PAGE_MASK_ ::= ~0x1F

  device_ /i2c.Device ::= ?
  last_write_us_ /int := -MAX_WRITE_OFFLINE_US_

  constructor .device_:

  /**
  Reads a single byte at address $at.
  The address must satisfy 0 <= $at < $SIZE.
  */
  operator[] at/int -> int:
    return (read at --size=1)[0]

  /**
  Writes a single byte $new_value at address $at.
  The address must satisfy 0 <= $at < $SIZE.
  */
  operator[]= at/int new_value/int -> none:
    write at #[new_value]

  /**
  Reads $size bytes starting at $address.
  The address must satisfy 0 <= $address <= $SIZE - $size.
  */
  read address/int --size=1 -> ByteArray:
    if size < 0: throw "INVALID_ARGUMENT"
    if not 0 <= address << address + size <= SIZE: throw "OUT_OF_RANGE"
    if size == 0: return #[]
    return try_: return device_.read_address #[ address >> 8, address & 0xFF ] size

  /**
  Writes the given $bytes starting at $address.
  The address must satisfy 0 <= $address <= $SIZE - ($bytes).size.
  */
  write address/int bytes/ByteArray -> none:
    if not 0 <= address << address + bytes.size <= SIZE: throw "OUT_OF_RANGE"
    if bytes.size == 0: return
    // The device is split into pages of 32 bytes.
    // Never write across page boundaries. The device would just wrap around.
    if address & PAGE_MASK_ == (address + bytes.size - 1) & PAGE_MASK_:
      write_page_ address bytes
      return

    // The address bits of the first page.
    first_page_offset := address - (address & PAGE_MASK_)
    first_page_bytes := PAGE_SIZE_ - first_page_offset
    List.chunk_up 0 bytes.size first_page_bytes PAGE_SIZE_: | from to |
      write_page_ (address + from) bytes[from..to]

  /**
  Writes the given $bytes to the $address.
  The $bytes must only write to one page.
  */
  write_page_ address/int bytes/ByteArray -> none:
    assert: address & PAGE_MASK_ == (address + bytes.size - 1) & PAGE_MASK_
    try_:
      device_.write_address #[ address >> 8, address & 0xFF ] bytes
      last_write_us_ = Time.monotonic_us

  try_ [block]:
    // After a write the device is offline for up to MAX_WRITE_OFFLINE_MS_.
    // Try the operation, but be ok if it fails.
    now := Time.monotonic_us
    while last_write_us_ + MAX_WRITE_OFFLINE_US_ >= now:
      catch: return block.call
      sleep --ms=1
    // If the device should have written, just do the operation.
    return block.call

