#!/usr/bin/env bash
set -euo pipefail

# `podman stats` has no Image/Pod fields — join those from `podman ps`.

mapfile -t stats_lines < <(
  podman stats --no-stream --format $'{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'
)

if [ "${#stats_lines[@]}" -eq 0 ]; then
  echo "No running containers."
  exit 0
fi

declare -A images=()
declare -A pods=()
show_pod=0
while IFS=$'\t' read -r name image pod; do
  [ -n "$name" ] || continue
  images["$name"]="$image"
  pods["$name"]="$pod"
  [ -n "$pod" ] && show_pod=1
done < <(podman ps --format $'{{.Names}}\t{{.Image}}\t{{.PodName}}')

{
  for line in "${stats_lines[@]}"; do
    IFS=$'\t' read -r name cpu mem memperc <<<"$line"
    if [ "$show_pod" -eq 1 ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" \
        "${pods[$name]:-}" \
        "${images[$name]:-?}" \
        "$cpu" \
        "$mem" \
        "$memperc"
    else
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$name" \
        "${images[$name]:-?}" \
        "$cpu" \
        "$mem" \
        "$memperc"
    fi
  done
} \
| if [ "$show_pod" -eq 1 ]; then
    sort -t$'\t' -k6 -nr \
    | awk -F'\t' '
      BEGIN { print "NAME\tPOD\tIMAGE\tCPU %\tMEM USAGE / LIMIT\tMEM %" }
      {
        print $0
        c=$4; gsub(/%/, "", c); tot_cpu += c
        m=$6; gsub(/%/, "", m); tot_mem_perc += m
        split($5, a, "/"); lim=a[2]
        match(a[1], /[0-9.]+/); v=substr(a[1], RSTART, RLENGTH)
        if (a[1] ~ /[Gg]/) v*=1024
        else if (a[1] ~ /[Kk]/) v/=1024
        else if (a[1] ~ /B/ && a[1] !~ /[MmgGkK]/) v/=(1024*1024)
        tot_mem += v
      }
      END {
        print "------\t---\t-----\t-------\t---------------------\t-------"
        gsub(/^[ \t]+|[ \t]+$/, "", lim)
        mem_fmt = (tot_mem >= 1024) ? sprintf("%.2fGiB", tot_mem/1024) : sprintf("%.2fMiB", tot_mem)
        printf "TOTAL\t\t\t%.2f%%\t%s / %s\t%.2f%%\n", tot_cpu, mem_fmt, lim, tot_mem_perc
      }'
  else
    sort -t$'\t' -k5 -nr \
    | awk -F'\t' '
      BEGIN { print "NAME\tIMAGE\tCPU %\tMEM USAGE / LIMIT\tMEM %" }
      {
        print $0
        c=$3; gsub(/%/, "", c); tot_cpu += c
        m=$5; gsub(/%/, "", m); tot_mem_perc += m
        split($4, a, "/"); lim=a[2]
        match(a[1], /[0-9.]+/); v=substr(a[1], RSTART, RLENGTH)
        if (a[1] ~ /[Gg]/) v*=1024
        else if (a[1] ~ /[Kk]/) v/=1024
        else if (a[1] ~ /B/ && a[1] !~ /[MmgGkK]/) v/=(1024*1024)
        tot_mem += v
      }
      END {
        print "------\t-----\t-------\t---------------------\t-------"
        gsub(/^[ \t]+|[ \t]+$/, "", lim)
        mem_fmt = (tot_mem >= 1024) ? sprintf("%.2fGiB", tot_mem/1024) : sprintf("%.2fMiB", tot_mem)
        printf "TOTAL\t\t%.2f%%\t%s / %s\t%.2f%%\n", tot_cpu, mem_fmt, lim, tot_mem_perc
      }'
  fi \
| column -t -s $'\t'
