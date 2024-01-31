"""Display a live FFT of values that come in over the serial port.
Incoming data is assumed to be raw, signed 8-bit integers.
"""
import os
import struct
import sys
import time
import threading
import queue

import gnuplotlib
import numpy
from scipy.fft import fft, fftfreq
import serial

num_samples_per_plot = 10_000
sample_rate = 40_000

def fetch_data(sample_queue, log_message_queue, ser):
  """Fetch signed integers from serial port and send them to the queue."""
  last_update = time.time()
  while True:
    data_bytes = ser.read(size=num_samples_per_plot)
    new_update = time.time()
    time_since_update = new_update - last_update
    last_update = new_update
    log_message = f'fetched {num_samples_per_plot} samples, {num_samples_per_plot/time_since_update} samp/sec'
    try:
      sample_queue.put_nowait(data_bytes)
    except queue.Full:
      pass
    try:
      log_message_queue.put_nowait(log_message)
    except queue.Full:
      pass

def main():
  # Use 576000 baud to match the PlutoLink UART.
  ser = serial.Serial('/dev/ttyUSB0', 576000, timeout=None)
  sample_queue = queue.Queue(maxsize=1)
  log_message_queue = queue.Queue(maxsize=1)
  fetch_thread = threading.Thread(target = fetch_data, args =(sample_queue, log_message_queue, ser)) 
  fetch_thread.start()

  t_axis = numpy.linspace(0.0, num_samples_per_plot/sample_rate, num_samples_per_plot, endpoint=False)
  f_axis = numpy.linspace(0.0, sample_rate/2, num_samples_per_plot, endpoint=False)

  while True:
    # Convert bytes to signed ints.
    data_bytes = sample_queue.get(block=True)
    data_ints = []
    for val in struct.iter_unpack('>b', data_bytes):
      data_ints.append(val)

    # Calculate the FFT.
    num_samples = len(data_ints)
    period = 1.0 / sample_rate
    fft_data = fft(data_ints)
    fft_mag = 2.0/num_samples * numpy.abs(fft_data[0:num_samples//2])
    fft_mag = fft_mag.flatten()
    f_axis = fftfreq(num_samples, period)[:num_samples//2]

    # Plot the FFT.
    os.system('cls' if os.name == 'nt' else 'clear')
    print(log_message_queue.get(block=True, timeout=0.2))
    gnuplotlib.plot(f_axis, fft_mag, _with='lines', terminal='dumb 160,40', unset='grid')

if __name__ == "__main__":
  sys.exit(main())