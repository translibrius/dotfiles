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
plan=""

# GLM mode: claude talking to z.ai, not Anthropic. Anthropic's rate_limits block
# is absent, so pull the plan's own quota from z.ai's (undocumented) endpoint the
# ZCode GUI uses: GET /api/monitor/usage/quota/limit, Authorization = raw key, no Bearer.
# limits[] entries: unit 3/number 5 = 5h window, unit 6/number 1 = weekly. percentage
# is % used, nextResetTime is ms. Shape reverse-engineered 2026-10, expect drift.
if [ -z "$h5" ] && { [[ "$ANTHROPIC_BASE_URL" == *z.ai* ]] || [[ "$model" == *[Gg][Ll][Mm]* ]]; }; then
  key="${ZAI_API_KEY:-$ANTHROPIC_AUTH_TOKEN}"
  cache="$HOME/.cache/glm-quota.json"
  if [ -n "$key" ]; then
    mkdir -p "$HOME/.cache" 2>/dev/null
    mtime=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
    # Refresh in the background past the TTL. The statusline repaints on every
    # keystroke; a blocking curl would stutter the prompt. This paint uses the
    # cache as-is (maybe stale, maybe absent); the next one picks up fresh data.
    if [ $(( $(date +%s) - mtime )) -gt 60 ]; then
      ( curl -s -m 8 -H "Authorization: $key" -H "Accept: application/json" \
          "https://api.z.ai/api/monitor/usage/quota/limit" -o "$cache.tmp" 2>/dev/null \
          && mv -f "$cache.tmp" "$cache" 2>/dev/null ) >/dev/null 2>&1 &
      disown 2>/dev/null
    fi
    if [ -s "$cache" ]; then
      read -r h5 h5r d7 plan < <(jq -r '
        (.data.limits // []) as $l
        | ($l[] | select(.unit==3) | .percentage) as $fh
        | ($l[] | select(.unit==3) | .nextResetTime) as $fr
        | ($l[] | select(.unit==6) | .percentage) as $wk
        | "\($fh // "") \(($fr // 0)/1000 | floor) \($wk // "") \(.data.level // "")"
      ' "$cache" 2>/dev/null)
      [ "$h5r" = "0" ] && h5r=""
    fi
  fi
fi

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

# Anthropic cost estimate is meaningless on z.ai; show the plan tier instead.
if [ -n "$plan" ]; then
  out+=" ${DIM}| ${plan}${R}"
elif [ -n "$cost" ]; then
  out+=" ${DIM}| \$$(printf '%.2f' "$cost")${R}"
fi

printf '%s' "$out"
