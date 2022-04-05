// Copyright (C) 2022 Toitware ApS. All rights reserved.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import gpio
import i2c
import cat24c32

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device cat24c32.I2C_ADDRESS
  eeprom := cat24c32.Cat24c32 device

  eeprom[0] = 0x63
  eeprom.write 1 #[
    0, 1, 2, 3,
    4, 5, 6, 7,
    8, 9, 10, 11,
    12, 13, 14, 15,
    16, 17, 18, 19,
    20, 21, 22, 23,
    24, 25, 26, 27,
    28, 29, 30, 31,
    32, 33, 34, 35,
    36, 37, 38, 39,
  ]
  45.repeat:
    print "$(%2d it): 0x$(%02x eeprom[it])"
  print (eeprom.read 1 --size=10)
