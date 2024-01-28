"""Average integers that come in over the UART.

Received bytes are treated as integers and averaged together. The sum is
periodically reset.

To install dependencies:
- pip3 install pyserial
"""
import sys

import serial

def main():
  ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=None)
  print('test')
  sum = 0
  num_samples = 0
  try:
    while True:
      sum += int.from_bytes(ser.read(), byteorder='big', signed=True)
      num_samples += 1
      print(f'average: {sum/num_samples:.2f}, num_samples: {num_samples}')
      if num_samples > 10e3:
        sum = 0
        num_samples = 0
  except KeyboardInterrupt:
    pass

  return 0

if __name__ == "__main__":
  sys.exit(main())