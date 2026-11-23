#!/usr/bin/env bash

# System info provider with jalpari-core fallback and pure /proc fallback
if [[ "$1" == "watch" ]]; then
    if command -v jalpari-core &>/dev/null; then
        exec jalpari-core "$@"
    fi
    interval="${4:-2}"
    while true; do
        python3 -c '
import json, os, glob, time

try:
    with open("/proc/stat") as f:
        fields = [float(x) for x in f.readline().strip().split()[1:]]
    idle1, total1 = fields[3], sum(fields)
    time.sleep(0.08)
    with open("/proc/stat") as f:
        fields = [float(x) for x in f.readline().strip().split()[1:]]
    idle2, total2 = fields[3], sum(fields)
    cpu = int(100 * (1 - (idle2 - idle1) / (total2 - total1))) if total2 > total1 else 0

    mem = {}
    with open("/proc/meminfo") as f:
        for line in f:
            parts = line.split(":")
            if len(parts) == 2:
                mem[parts[0].strip()] = int(parts[1].strip().split()[0])
    total_kb = mem.get("MemTotal", 1)
    avail_kb = mem.get("MemAvailable", 0)
    ram_percent = int(100 * (1 - avail_kb / total_kb))
    ram_gb = round((total_kb - avail_kb) / (1024 * 1024), 1)

    st = os.statvfs("/")
    total_b = st.f_blocks * st.f_frsize
    used_b = total_b - (st.f_bavail * st.f_frsize)
    disk_percent = int(100 * used_b / total_b) if total_b > 0 else 0
    disk_used_gb = round(used_b / (1024**3), 1)
    disk_total_gb = round(total_b / (1024**3), 1)

    temp = 0
    for t in sorted(glob.glob("/sys/class/thermal/thermal_zone*/temp")):
        try:
            with open(t) as f:
                v = int(f.read().strip()) // 1000
                if 10 < v < 110:
                    temp = v
                    break
        except:
            pass

    print(json.dumps({
        "cpu": cpu,
        "ramPercent": ram_percent,
        "ramGb": ram_gb,
        "diskPercent": disk_percent,
        "diskUsedGb": disk_used_gb,
        "diskTotalGb": disk_total_gb,
        "temp": temp,
        "netRx": 0,
        "netTx": 0
    }))
except Exception:
    pass
' 2>/dev/null || true
        sleep "$interval"
    done
else
    if command -v jalpari-core &>/dev/null; then
        exec jalpari-core "$@"
    fi
    python3 -c '
import json, os, glob
mem = {}
with open("/proc/meminfo") as f:
    for line in f:
        parts = line.split(":")
        if len(parts) == 2:
            mem[parts[0].strip()] = int(parts[1].strip().split()[0])
total_kb = mem.get("MemTotal", 1)
avail_kb = mem.get("MemAvailable", 0)
st = os.statvfs("/")
total_b = st.f_blocks * st.f_frsize
used_b = total_b - (st.f_bavail * st.f_frsize)
temp = 0
for t in sorted(glob.glob("/sys/class/thermal/thermal_zone*/temp")):
    try:
        with open(t) as f:
            v = int(f.read().strip()) // 1000
            if 10 < v < 110:
                temp = v
                break
    except:
        pass
print(json.dumps({
    "cpu": 0,
    "ramPercent": int(100 * (1 - avail_kb / total_kb)),
    "ramGb": round((total_kb - avail_kb) / (1024 * 1024), 1),
    "diskPercent": int(100 * used_b / total_b) if total_b > 0 else 0,
    "diskUsedGb": round(used_b / (1024**3), 1),
    "diskTotalGb": round(total_b / (1024**3), 1),
    "temp": temp,
    "netRx": 0,
    "netTx": 0
}))
' 2>/dev/null || true
fi
