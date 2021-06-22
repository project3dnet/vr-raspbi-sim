# vr-raspbi-sim
Simulation Raspberry Pi beacon / BLE advertisement

Usage:

```
$ curl -O "https://raw.githubusercontent.com/google/eddystone/master/eddystone-url/implementations/linux/advertise-url" && chmod +x advertise-url

[...]

$ ./eddystone-url-sim.sh --help
Usage: eddystone-url-sim.sh [-h] [-v] [-t]

Simulation Raspberry Pi beacon / BLE advertisement

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-t, --time      Cooldown time, default 10
```
