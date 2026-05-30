#!/bin/bash

# <swiftbar.title>Charging Wattage</swiftbar.title>
# <swiftbar.author>Denis Dobraš</swiftbar.author>
# <swiftbar.desc>Live wattage drawn from the power adapter, in the menu bar.</swiftbar.desc>
# <swiftbar.version>1.1.0</swiftbar.version>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>

set -u

data=$(/usr/sbin/ioreg -rn AppleSmartBattery)

# Top-level scalar like:    "IsCharging" = Yes
top () {
  printf '%s\n' "$data" \
    | awk -v k="\"$1\"" -F' = ' '$1 ~ k {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

# Nested fields inside one-line dicts like:
#   "AdapterDetails" = {"Watts"=96,"Name"="Apple 96W ...", ...}
nested () {
  local section="$1" key="$2"
  printf '%s\n' "$data" \
    | grep "\"$section\"" \
    | grep -oE "\"$key\"=([0-9]+|\"[^\"]*\")" \
    | head -1 \
    | sed -E "s/^\"$key\"=//; s/^\"//; s/\"$//"
}

# SF Symbol matching the battery level, à la Control Center.
# Uses the .percent variants (SF Symbols 5+) which match the native
# macOS menu bar battery indicator — outlined, modern, system-tinted.
battery_symbol () {
  local pct=$1
  if   [ "$pct" -ge 80 ]; then echo "battery.100percent"
  elif [ "$pct" -ge 60 ]; then echo "battery.75percent"
  elif [ "$pct" -ge 40 ]; then echo "battery.50percent"
  elif [ "$pct" -ge 20 ]; then echo "battery.25percent"
  else                         echo "battery.0percent"
  fi
}

ext_connected=$(top ExternalConnected)
is_charging=$(top IsCharging)
capacity=$(top CurrentCapacity)

adapter_watts=$(nested AdapterDetails Watts)
adapter_name=$(nested AdapterDetails Name)
adapter_desc=$(nested AdapterDetails Description)
adapter_voltage_mv=$(nested AdapterDetails AdapterVoltage)
adapter_current_ma=$(nested AdapterDetails Current)

system_power_in_mw=$(nested PowerTelemetryData SystemPowerIn)
system_load_mw=$(nested PowerTelemetryData SystemLoad)

power_in_w=$(awk -v x="${system_power_in_mw:-0}" 'BEGIN {printf "%.1f", x/1000}')
load_w=$(awk    -v x="${system_load_mw:-0}"     'BEGIN {printf "%.1f", x/1000}')

# ── Menu bar line ──────────────────────────────────────────────
# `symbolize=true` makes SwiftBar swap `:symbol.name:` tokens for the
# actual SF Symbol image, so we can position the icon *after* the text
# the way the native macOS battery indicator does.
#
# Two independent knobs:
#   size=N    → percentage TEXT font size
#   sfsize=N  → the embedded SF Symbol (battery) size, sized separately
# This is how we get small text next to a larger, clearly-outlined battery
# glyph that matches the native macOS menu bar indicator.
TEXT_SIZE=11
ICON_SIZE=16
MBAR_STYLE="symbolize=true size=${TEXT_SIZE} sfsize=${ICON_SIZE}"

if [ "$ext_connected" = "Yes" ]; then
  if [ "$is_charging" = "Yes" ]; then
    printf "%sW :battery.100percent.bolt: | %s color=#22c55e\n" "$power_in_w" "$MBAR_STYLE"
  else
    printf "%s%% :battery.100percent.bolt: | %s\n" "$capacity" "$MBAR_STYLE"
  fi
else
  sym=$(battery_symbol "$capacity")
  if [ "$capacity" -lt 20 ]; then
    printf "%s%% :%s: | %s color=#ef4444\n" "$capacity" "$sym" "$MBAR_STYLE"
  else
    printf "%s%% :%s: | %s\n" "$capacity" "$sym" "$MBAR_STYLE"
  fi
fi

# ── Dropdown ───────────────────────────────────────────────────
echo "---"
echo "Battery: ${capacity}% | sfimage=$(battery_symbol "$capacity")"

if [ "$ext_connected" = "Yes" ]; then
  if [ "$is_charging" = "Yes" ]; then
    echo "Status: Charging | sfimage=bolt.fill"
  else
    echo "Status: Plugged in (not charging) | sfimage=powerplug.fill"
  fi

  if [ -n "${adapter_watts:-}" ]; then
    label="${adapter_name:-${adapter_desc:-Adapter}}"
    echo "${label}: ${adapter_watts}W rated | sfimage=bolt.batteryblock.fill"
  fi

  echo "Live draw: ${power_in_w} W | sfimage=bolt.horizontal.fill"

  if [ -n "${adapter_voltage_mv:-}" ] \
     && [ -n "${adapter_current_ma:-}" ] \
     && [ "$adapter_voltage_mv" != "0" ]; then
    v=$(awk -v x="$adapter_voltage_mv" 'BEGIN {printf "%.1f", x/1000}')
    a=$(awk -v x="$adapter_current_ma" 'BEGIN {printf "%.2f", x/1000}')
    echo "Negotiated: ${v} V × ${a} A | sfimage=waveform.path"
  fi
else
  echo "Status: On battery | sfimage=$(battery_symbol "$capacity")"
fi

echo "System load: ${load_w} W | sfimage=cpu"
echo "---"
echo "Refresh | refresh=true sfimage=arrow.clockwise"
