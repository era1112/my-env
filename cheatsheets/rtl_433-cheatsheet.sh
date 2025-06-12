#!/bin/bash

# Sample rate is default (1M). Seems to have the best performance.
# Used on rtl-sdr w/ pctel low-pro 4g antenna
# Freqs: TPMS (315, 433), home automation (433), APRS (144 [nodec]), LORA (905 [nodec]), ADSB (910 [nodec])
# This script defines a 10 minute block. For ease of analysis, start it at time xx:x0.00 (using at command)

# During analysis, freqs will align with M:SS as follows:
# 0:00 144
# 0:30 301
# 1:00 315
# 6:00 345
# 6:30 434
# 7:00 433
# 8:30 868
# 9:00 910
# 9:30 910

rtl_433 \
-f 144M \
-f 301M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 315M \
-f 345M \
-f 434M \
-f 433M \
-f 433M \
-f 433M \
-f 868M \
-f 910M \
-f 915M \
-H 30 -M hires `# hop every 60 secs, usec precision, auto-sets detection thresh vs noise`\
-F csv:/home/user/loot/rtl433/loot.csv -F kv -v -M level -M stats:1:600 `# records RSSI/SNR, output to csv, summary report to stdout every cycle (10 min)`


# TODO:
# [-Y auto | classic | minmax] FSK pulse detector mode.
# [-Y autolevel] Set minlevel automatically based on average estimated noise.
# [-Y ampest | magest] Choose amplitude or magnitude level estimator.
# [-s <sample rate>] Set sample rate (default: 250000 Hz)
# [-p <ppm_error>] Correct rtl-sdr tuner frequency offset error (default: 0)
# [-g <gain> | help] (default: auto)
# [-t <settings>] apply a list of keyword=value settings to the SDR device
# -M bits
# -M "protocol" / "noprotocol" to output the decoder protocol number meta data.
