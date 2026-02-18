function psg --description "Search running processes by name"
  if test (count $argv) -eq 0
    echo "Usage: psg <pattern>"
    return 1
  end

  set -l pids (pgrep -fi $argv[1])
  if test $status -ne 0
    echo "No matching processes found."
    return 1
  end

  ps -ww -o pid,ppid,%cpu,%mem,stat,start,command -p (string join , $pids)
end
