#!/bin/bash

# <swiftbar.title>Charging Wattage</swiftbar.title>
# <swiftbar.author>Denis</swiftbar.author>
# <swiftbar.desc>Shows live wattage drawn from the power adapter.</swiftbar.desc>
# <swiftbar.version>1.0</swiftbar.version>
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

# ── Menu bar line ───────────────────────────────────────────────
if [ "$ext_connected" = "Yes" ]; then
  if [ "$is_charging" = "Yes" ]; then
    printf "⚡ %sW | color=#22c55e\n" "$power_in_w"
  else
    printf "🔌 %s%%\n" "$capacity"
  fi
else
  printf "🔋 %s%%\n" "$capacity"
fi

# ── Dropdown ────────────────────────────────────────────────────
echo "---"
echo "Battery: ${capacity}%"

if [ "$ext_connected" = "Yes" ]; then
  if [ "$is_charging" = "Yes" ]; then
    echo "Status: Charging"
  else
    echo "Status: Plugged in (not charging)"
  fi

  if [ -n "${adapter_watts:-}" ]; then
    label="${adapter_name:-${adapter_desc:-Adapter}}"
    echo "${label}: ${adapter_watts}W rated"
  fi

  echo "Live draw: ${power_in_w} W"

  if [ -n "${adapter_voltage_mv:-}" ] \
     && [ -n "${adapter_current_ma:-}" ] \
     && [ "$adapter_voltage_mv" != "0" ]; then
    v=$(awk -v x="$adapter_voltage_mv" 'BEGIN {printf "%.1f", x/1000}')
    a=$(awk -v x="$adapter_current_ma" 'BEGIN {printf "%.2f", x/1000}')
    echo "Negotiated: ${v} V × ${a} A"
  fi
else
  echo "Status: On battery"
fi

echo "System load: ${load_w} W"
echo "---"
echo "Refresh | refresh=true"
