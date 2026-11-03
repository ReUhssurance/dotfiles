# wt — git worktree wrapper with numeric indices
#
#   wt                 list worktrees with indices
#   wt list            same (also: wt ls)
#   wt <n>             cd to worktree n
#   wt remove <n>      git worktree remove <path of n>
#   wt add <branch>    create worktree as sibling dir and cd into it
#   wt add <br> <path> passthrough to git worktree add
#   wt <anything>      passthrough to git worktree <anything>

unalias wt 2>/dev/null

_wt_table() {
  git worktree list --porcelain 2>/dev/null | awk '
    /^worktree /{ p=substr($0,10); b=""; h="" }
    /^HEAD /{ h=substr($0,6) }
    /^branch /{ b=substr($0,8); sub(/^refs\/heads\//,"",b) }
    /^detached$/{ b="(detached)" }
    /^bare$/{ b="(bare)" }
    /^$/{ if (p!="") { printf "%s\t%s\t%s\n", p, (b==""?"-":b), substr(h,1,8); p="" } }
    END{ if (p!="") printf "%s\t%s\t%s\n", p, (b==""?"-":b), substr(h,1,8) }
  '
}

_wt_path_at() {
  local -a rows
  rows=("${(@f)$(_wt_table)}")
  local idx=$1
  (( idx < 0 || idx >= ${#rows} )) && return 1
  print -r -- "${${(@s:	:)rows[idx+1]}[1]}"
}

_wt_list() {
  local -a rows
  rows=("${(@f)$(_wt_table)}")
  local here
  here=$(git rev-parse --show-toplevel 2>/dev/null)
  local i=0 row wtp branch head mark w=0
  for row in $rows; do
    branch="${${(@s:	:)row}[2]}"
    (( ${#branch} > w )) && w=${#branch}
  done
  for row in $rows; do
    wtp="${${(@s:	:)row}[1]}"
    branch="${${(@s:	:)row}[2]}"
    head="${${(@s:	:)row}[3]}"
    [[ $wtp == $here ]] && mark='*' || mark=' '
    printf '%s %d  %-*s  %-8s  %s\n' "$mark" $i $w "$branch" "$head" "$wtp"
    i=$(( i + 1 ))
  done
  return 0
}

wt() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print -u2 "wt: not inside a git repository"
    return 1
  fi

  local cmd=$1

  case $cmd in
    ''|list|ls)
      _wt_list
      ;;

    <->)
      local wtp
      if ! wtp=$(_wt_path_at $cmd); then
        print -u2 "wt: no worktree at index $cmd"
        return 1
      fi
      cd -- "$wtp"
      ;;

    cd)
      if [[ -z $2 ]]; then
        print -u2 "wt: usage: wt cd <n>"
        return 1
      fi
      wt "$2"
      ;;

    remove|rm)
      shift
      local -a args
      local a wtp
      for a in "$@"; do
        if [[ $a == <-> ]]; then
          if ! wtp=$(_wt_path_at $a); then
            print -u2 "wt: no worktree at index $a"
            return 1
          fi
          args+=("$wtp")
        else
          args+=("$a")
        fi
      done
      local here main
      here=$(git rev-parse --show-toplevel 2>/dev/null)
      if (( ${args[(I)$here]} )); then
        main=$(_wt_path_at 0) && cd -- "$main"
      fi
      git worktree remove "${args[@]}"
      ;;

    add)
      if [[ $# -eq 2 && $2 != -* && $2 != /* && $2 != .* && ! -e $2 ]]; then
        local branch=$2 root parent dest slug
        root=$(git rev-parse --show-toplevel)
        parent=${root:h}
        slug=${branch//\//-}
        dest=$parent/${root:t}-$slug
        if git show-ref --verify --quiet "refs/heads/$branch"; then
          git worktree add "$dest" "$branch" || return
        else
          git worktree add -b "$branch" "$dest" || return
        fi
        cd -- "$dest"
      else
        shift
        git worktree add "$@"
      fi
      ;;

    *)
      git worktree "$@"
      ;;
  esac
}

_wt() {
  local -a subcmds idxs
  subcmds=(list ls add remove rm move lock unlock prune repair cd)
  if (( CURRENT == 2 )); then
    idxs=(${(f)"$(_wt_table | awk '{ printf "%d:%s\n", NR-1, $0 }' | sed 's/\t/ /g')"})
    _describe -t index 'worktree' idxs
    _describe -t command 'subcommand' subcmds
  elif [[ ${words[2]} == (remove|rm|cd|move|lock|unlock) ]]; then
    idxs=(${(f)"$(_wt_table | awk '{ printf "%d:%s\n", NR-1, $0 }' | sed 's/\t/ /g')"})
    _describe -t index 'worktree' idxs
  fi
}

compdef _wt wt 2>/dev/null
