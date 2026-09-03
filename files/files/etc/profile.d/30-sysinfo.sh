#!/bin/sh
# BITS-WRT system info on shell login

[ -f /etc/openwrt_release ] && {
    REL="$(sed -n "s/^DISTRIB_DESCRIPTION='\(.*\)'/\1/p" /etc/openwrt_release)"
    [ -n "$REL" ] && printf '  Firmware : %s\n' "$REL"
}

printf '  Kernel   : %s\n' "$(uname -r)"

U="$(cut -d. -f1 /proc/uptime)"
D=$((U/86400)); H=$((U%86400/3600)); M=$((U%3600/60))
printf '  Uptime   : %dd %dh %dm\n' "$D" "$H" "$M"

printf '  Load     : %s\n' "$(cut -d' ' -f1-3 /proc/loadavg)"

M0="$(awk '/^MemTotal/{t=$2}/^MemAvailable/{a=$2}END{if(t)printf "%.0fM / %.0fM", (t-a)/1024, t/1024}' /proc/meminfo)"
[ -n "$M0" ] && printf '  Memory   : %s used\n' "$M0"

for t in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$t" ] && { printf '  Temp     : %s C\n' "$(( $(cat "$t") / 1000 ))"; break; }
done

echo