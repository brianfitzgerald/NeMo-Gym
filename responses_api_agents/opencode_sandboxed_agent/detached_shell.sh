#!/bin/sh
# Shell for the OpenCode bash tool: output goes through a file, so background processes do not keep the tool call open.
sh=/bin/sh
[ -x /bin/bash ] && sh=/bin/bash
f=$(mktemp /tmp/nemo-gym-shell.XXXXXX) || exec "$sh" "$@"
"$sh" "$@" >"$f" 2>&1 </dev/null &
pid=$!
tpid=
trap 'kill $pid $tpid 2>/dev/null; rm -f "$f"; exit 143' TERM INT HUP
if tail --pid=$$ -n 0 /dev/null 2>/dev/null; then
  tail -s 0.2 --pid=$pid -n +1 -f "$f" &
  tpid=$!
  wait $tpid
else
  while kill -0 $pid 2>/dev/null; do sleep 1; done
  cat "$f"
fi
wait $pid
rc=$?
rm -f "$f"
exit $rc
