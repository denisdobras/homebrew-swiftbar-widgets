# Charging Wattage — SwiftBar plugin

A tiny SwiftBar plugin that shows the **live wattage** your MacBook is drawing from its power adapter, right in the menu bar. Uses native macOS **SF Symbols** so it blends into the system UI.

| State | Menu bar shows |
|---|---|
| Charging | `battery.100.bolt` SF Symbol + e.g. `60.1W` in system green |
| Plugged in, fully charged | `powerplug.fill` SF Symbol + percentage |
| On battery | Level-aware battery SF Symbol (`battery.0` / `.25` / `.50` / `.75` / `.100`) + percentage |
| Low battery (< 20 %) | Battery SF Symbol + percentage tinted red |

Click for adapter name, rated wattage, and the negotiated USB-PD profile (volts × amps). Dropdown rows have their own SF Symbols too (`cpu` for system load, `waveform.path` for the negotiated USB-PD profile, `arrow.clockwise` for refresh).

## Install via Homebrew

```sh
brew install --cask swiftbar              # if you don't have SwiftBar yet
brew tap denisdobras/swiftbar-widgets
brew install charging-wattage
```

Then follow the post-install caveats to symlink the plugin into SwiftBar's plugin folder, and refresh SwiftBar.

## Manual install

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar/releases).
2. Copy [`charging-wattage.3s.sh`](charging-wattage.3s.sh) into your SwiftBar plugin folder.
3. Make sure it's executable:
   ```sh
   chmod +x charging-wattage.3s.sh
   ```
4. SwiftBar menu → **Refresh All**.

## How it works

Every 3 seconds (the `3s` in the filename is the refresh interval), SwiftBar runs the script. The script makes one call to `ioreg -rn AppleSmartBattery` — the same source `pmset`, Activity Monitor, and System Information use — and parses out:

- `PowerTelemetryData.SystemPowerIn` — actual milliwatts being drawn from the wall **right now**. This is what shows in the menu bar.
- `AdapterDetails.Watts` — the adapter's rated max (shown in the dropdown so you can see e.g. `67.3 W of 96 W rated`).
- `AdapterDetails.AdapterVoltage` × `Current` — the negotiated USB-PD profile (e.g. `20.0 V × 4.70 A`).
- `CurrentCapacity`, `IsCharging`, `ExternalConnected` — the obvious state bits.

No daemons, no entitlements, no background processes. Just a 60-line POSIX shell script.

## Tweaking the refresh rate

The interval is encoded in the filename. Rename to taste:

| Filename | Refresh |
|---|---|
| `charging-wattage.1s.sh` | every 1 second |
| `charging-wattage.3s.sh` | every 3 seconds (default) |
| `charging-wattage.10s.sh` | every 10 seconds |

## Requirements

- macOS (uses `ioreg`, an Apple-only tool)
- [SwiftBar](https://github.com/swiftbar/SwiftBar) ≥ 1.5
- A Mac with a battery (i.e. a MacBook — desktop Macs don't expose `AppleSmartBattery`)

## License

MIT — see [LICENSE](LICENSE).
