"""Average integers that come in over the UART.

Received bytes are treated as integers and averaged together. The sum is
periodically reset.

To install dependencies:
- pip3 install pyserial
"""
import sys

import serial

def main():
  # Use 576000 baud to match the PlutoLink UART.
  ser = serial.Serial('/dev/ttyUSB0', 576000, timeout=None)
  sum = 0
  max_value = 0
  num_samples = 0
  try:
    while True:
      new_value = int.from_bytes(ser.read(size=1), byteorder='big', signed=True)
      if abs(new_value) > max_value:
        max_value = abs(new_value)
      sum += new_value
      num_samples += 1
      if (num_samples % 1000) == 0:
        print(f'new_value: {new_value},\tmax: {max_value},\tavg: {sum/num_samples:.2f},\tnum_samples: {num_samples}')
      if num_samples > 10e3:
        sum = 0
        num_samples = 0
        max_value = 0
  except KeyboardInterrupt:
    pass

  return 0

if __name__ == "__main__":
  sys.exit(main())