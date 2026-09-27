#!/bin/bash
# Feeds the Oblivion Signal rail one JSON vitals line per tick. CPU% and net
# throughput are deltas measured across the sleep window.

cpu_totals() {
  # -> "<busy> <idle>" jiffies since boot
  awk 'NR==1 { print $2+$3+$4+$7+$8, $5+$6; exit }' /proc/stat
}

net_totals() {
  # -> "<rx_bytes> <tx_bytes>" across all interfaces except lo
  awk -F'[: ]+' 'NR>2 && $2 != "lo" { rx += $3; tx += $11 } END { print rx+0, tx+0 }' /proc/net/dev
}

cpu_temp() {
  local h n d t z
  for h in /sys/class/hwmon/hwmon*/name; do
    [[ -f $h ]] || continue
    n=$(<"$h")
    case $n in
      k10temp | coretemp | zenpower | cpu_thermal)
        d=${h%/name}
        for t in "$d"/temp*_input; do
          [[ -f $t ]] || continue
          echo $(($(<"$t") / 1000))
          return
        done
        ;;
    esac
  done
  for z in /sys/class/thermal/thermal_zone*/temp; do
    [[ -f $z ]] || continue
    echo $(($(<"$z") / 1000))
    return
  done
  echo -1
}

mem_pct() {
  awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d", 100 * (t - a) / t }' /proc/meminfo
}

pwr() {
  local b s=""
  for b in /sys/class/power_supply/BAT*/capacity; do
    [[ -f $b ]] || continue
    [[ -f ${b%/capacity}/status ]] && s=$(<"${b%/capacity}/status")
    if [[ $s == "Charging" ]]; then
      echo "+$(<"$b")"
    else
      echo "$(<"$b")"
    fi
    return
  done
  echo "AC"
}

disk_pct() {
  df -P / | awk 'NR==2 { gsub(/%/, "", $5); print $5 }'
}

uptime_short() {
  # DSEG7 has no 'm' glyph — under a day, render clock-style HH:MM:SS.
  awk '{ s = int($1); d = int(s / 86400); r = s % 86400; h = int(r / 3600); m = int(r % 3600 / 60); sec = r % 60;
    if (d > 0) printf "%dd%02dh", d, h;
    else printf "%d:%02d:%02d", h, m, sec }' /proc/uptime
}

while :; do
  read -r busy_a idle_a <<<"$(cpu_totals)"
  read -r rx_a tx_a <<<"$(net_totals)"
  sleep 2
  read -r busy_b idle_b <<<"$(cpu_totals)"
  read -r rx_b tx_b <<<"$(net_totals)"

  d_busy=$((busy_b - busy_a))
  d_idle=$((idle_b - idle_a))
  if (( d_busy + d_idle > 0 )); then
    cpu=$((100 * d_busy / (d_busy + d_idle)))
  else
    cpu=0
  fi
  rx=$(( (rx_b - rx_a) / 2 ))
  tx=$(( (tx_b - tx_a) / 2 ))

  printf '{"cpu":%d,"temp":%d,"mem":%d,"rx":%d,"tx":%d,"pwr":"%s","disk":%d,"up":"%s"}\n' \
    "$cpu" "$(cpu_temp)" "$(mem_pct)" "$rx" "$tx" "$(pwr)" "$(disk_pct)" "$(uptime_short)"
done
