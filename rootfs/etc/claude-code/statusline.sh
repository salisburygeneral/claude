#!/bin/sh
# Claude Code status line: "sg │ <model> <effort> │ context NN% │ usage 5h NN% 7d NN%"
exec jq -j '
  # Green below 50%, yellow from 50%, red from 80%
  def pct: round | "\u001b[\(if . >= 80 then 31 elif . >= 50 then 33 else 32 end)m\(.)%\u001b[0m";

  [ "\u001b[1;36msg\u001b[0m",
    ([.model.display_name, .effort.level] | map(values) | join(" ") | ascii_downcase),
    "context \(.context_window.used_percentage | if . then pct else "--" end)",
    ([["5h", .rate_limits.five_hour.used_percentage], ["7d", .rate_limits.seven_day.used_percentage]]
      | map(select(.[1]) | "\(.[0]) \(.[1] | pct)")
      | if length > 0 then "usage " + join(" ") else "" end)
  ] | map(select(. != "")) | join(" │ ")
'
