#!/usr/bin/env bash
# Claude Code status line: model | repo:branch | ctx left | 5h left (reset) | 7d left | cost
in=$(cat)
j() { jq -r "$1 // empty" <<<"$in"; }

model=$(j '.model.display_name')
dir=$(j '.workspace.project_dir'); [ -z "$dir" ] && dir=$(j '.cwd')
cur=$(j '.workspace.current_dir')
ctx=$(j '.context_window.remaining_percentage')
h5=$(j '.rate_limits.five_hour.used_percentage')
h5r=$(j '.rate_limits.five_hour.resets_at')
d7=$(j '.rate_limits.seven_day.used_percentage')
cost=$(j '.cost.total_cost_usd')

R=$'\e[0m'; DIM=$'\e[2m'; C=$'\e[36m'; M=$'\e[35m'
# green >50, yellow >20, red otherwise (input is "% left")
col() { local v=${1%.*}; if [ "$v" -gt 50 ]; then printf '\e[32m'; elif [ "$v" -gt 20 ]; then printf '\e[33m'; else printf '\e[31m'; fi; }

out="${M}${model}${R}"

repo=$(basename "${dir:-$PWD}")
branch=$(git -C "${cur:-$dir}" symbolic-ref --short HEAD 2>/dev/null || git -C "${cur:-$dir}" rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  dirty=$(git -C "${cur:-$dir}" status --porcelain 2>/dev/null | head -1)
  out+=" ${DIM}|${R} ${C}${repo}${R}:${branch}${dirty:+*}"
else
  out+=" ${DIM}|${R} ${C}${repo}${R}"
fi

[ -n "$ctx" ] && out+=" ${DIM}|${R} ctx $(col "$ctx")${ctx%.*}%${R}"

if [ -n "$h5" ]; then
  left=$((100 - ${h5%.*}))
  rs=""
  if [ -n "$h5r" ]; then
    s=$(( h5r - $(date +%s) )); [ "$s" -lt 0 ] && s=0
    rs=" ${DIM}↻$((s/3600))h$(( (s%3600)/60 ))m${R}"
  fi
  out+=" ${DIM}|${R} 5h $(col "$left")${left}%${R}${rs}"
fi
if [ -n "$d7" ]; then
  left=$((100 - ${d7%.*}))
  out+=" ${DIM}|${R} 7d $(col "$left")${left}%${R}"
fi

[ -n "$cost" ] && out+=" ${DIM}| \$$(printf '%.2f' "$cost")${R}"

printf '%s' "$out"
