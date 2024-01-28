"""Configure the PlutoLink AD9363 SDR IC using libiio.

To install dependencies:
- sudo apt-get install libiio libiio-dev libiio-utils
- pip3 install pyadi-iio
"""
import decimal
import sys
import time

from adi import ad9363

class plutolink_ad9363(ad9363):
    # The data interface has been removed from the device tree, so don't try to
    # connect to it. We're using libiio only for configuration via SPI.
    _rx_data_device_name = ""
    _tx_data_device_name = ""

    @property
    def rssi(self):
        """rssi: receiver RSSI measurement."""
        return self._get_iio_attr("voltage0", "rssi", False)

def main():
  sdr = plutolink_ad9363(uri="ip:192.168.2.1")

  # RX Config
  # rx_rf_bandwidth gets set by the filter config below
  sdr.rx_enabled_channels = [0]
  sdr.rx_lo = 2_398_000_000
  sdr.gain_control_mode_chan0 = "slow_attack"

  # TX Config
  # tx_rf_bandwidth gets set by the filter config below
  sdr.tx_enabled_channels = [0]
  sdr.tx_lo = 2_393_000_000
  sdr.tx_cyclic_buffer = True
  sdr.tx_hardwaregain_chan0 = -30

  # Set the filters and sample rates using the output of the AD9363 Matlab
  # Filter Design Wizard.
  sdr.filter = "plutolink_ad9363_filter_settings.ftr"

  print('-----')
  print('Common settings:')
  print(f'filter: {sdr.filter}')
  print(f'sample_rate: {sdr.sample_rate}')
  print(f'loopback: {sdr.loopback}')

  print('-----')
  print('RX Config:')
  print(f'rx_enabled_channels: {sdr.rx_enabled_channels}')
  print(f'rx_lo: {sdr.rx_lo}')
  print(f'rx_rf_bandwidth: {sdr.rx_rf_bandwidth}')
  print(f'rx_hardwaregain_chan0: {sdr.rx_hardwaregain_chan0}')
  print(f'gain_control_mode_chan0: {sdr.gain_control_mode_chan0}')

  print('-----')
  print('TX Config:')
  print(f'tx_enabled_channels: {sdr.tx_enabled_channels}')
  print(f'tx_lo: {sdr.tx_lo}')
  print(f'tx_rf_bandwidth: {sdr.tx_rf_bandwidth}')
  print(f'tx_cyclic_buffer: {sdr.tx_cyclic_buffer}')
  print(f'tx_hardwaregain_chan0: {sdr.tx_hardwaregain_chan0}')

  print('-----')
  try:
    while True:
      print(f'gain: {sdr.rx_hardwaregain_chan0}, rssi: {sdr.rssi}')
      time.sleep(1)
  except KeyboardInterrupt:
    pass

if __name__ == "__main__":
  sys.exit(main())