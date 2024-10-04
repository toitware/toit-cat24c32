# CAT24C32

Toit driver for the CAT24C32 (or similar) EEPROM.

## Usage

A simple usage example.

```
import gpio
import i2c
import cat24c32

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device cat24c32.I2C-ADDRESS
  eeprom := cat24c32.Cat24c32 device

  eeprom[0] = 0x63
  eeprom.write 4 #[ 1, 2 3 ]
  8.repeat: print eeprom[it]
  print (eeprom.read 0 --size=10)
```

See the `examples` folder for more examples.

## References

Datasheet: https://www.onsemi.com/pdf/datasheet/cat24c32-d.pdf

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/toitware/toit-cat24c32/issues
