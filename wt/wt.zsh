# wt — git worktree wrapper with numeric indices (works in bash and zsh)
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

_wt_isnum() {
  case $1 in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

_wt_path_at() {
  _wt_table | awk -F'\t' -v i="$1" 'NR==i+1 { print $1; f=1 } END { exit !f }'
}

_wt_list() {
  local here
  here=$(git rev-parse --show-toplevel 2>/dev/null)
  _wt_table | awk -F'\t' -v here="$here" '
    { p[NR]=$1; b[NR]=$2; h[NR]=$3; if (length($2) > w) w = length($2) }
    END {
      fmt = "%s %d  %-" w "s  %-8s  %s\n"
      for (i = 1; i <= NR; i++)
        printf fmt, (p[i]==here ? "*" : " "), i-1, b[i], h[i], p[i]
    }
  '
}

wt() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "wt: not inside a git repository" >&2
    return 1
  fi

  local cmd=$1
  local wtp a here main branch root parent dest slug
  local -a args

  if _wt_isnum "$cmd"; then
    if ! wtp=$(_wt_path_at "$cmd"); then
      echo "wt: no worktree at index $cmd" >&2
      return 1
    fi
    cd -- "$wtp"
    return
  fi

  case $cmd in
    ''|list|ls)
      _wt_list
      ;;

    cd)
      if [[ -z $2 ]]; then
        echo "wt: usage: wt cd <n>" >&2
        return 1
      fi
      wt "$2"
      ;;

    remove|rm)
      shift
      args=()
      for a in "$@"; do
        if _wt_isnum "$a"; then
          if ! wtp=$(_wt_path_at "$a"); then
            echo "wt: no worktree at index $a" >&2
            return 1
          fi
          args+=("$wtp")
        else
          args+=("$a")
        fi
      done
      here=$(git rev-parse --show-toplevel 2>/dev/null)
      for a in "${args[@]}"; do
        if [[ $a == "$here" ]]; then
          main=$(_wt_path_at 0) && cd -- "$main"
          break
        fi
      done
      git worktree remove "${args[@]}"
      ;;

    add)
      if [[ $# -eq 2 && $2 != -* && $2 != /* && $2 != .* && ! -e $2 ]]; then
        branch=$2
        root=$(git rev-parse --show-toplevel)
        parent=$(dirname -- "$root")
        slug=${branch//\//-}
        dest=$parent/$(basename -- "$root")-$slug
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

# "<n>:<branch> <head> <path>" entries for completion
_wt_entries() {
  _wt_table | awk -F'\t' '{ printf "%d:%s %s %s\n", NR-1, $2, $3, $1 }'
}

if [ -n "$ZSH_VERSION" ]; then
  _wt() {
    local -a subcmds idxs
    local line
    subcmds=(list ls add remove rm move lock unlock prune repair cd)
    idxs=()
    while IFS= read -r line; do idxs+=("$line"); done < <(_wt_entries)
    if (( CURRENT == 2 )); then
      _describe -t index 'worktree' idxs
      _describe -t command 'subcommand' subcmds
    else
      case ${words[2]} in
        remove|rm|cd|move|lock|unlock) _describe -t index 'worktree' idxs ;;
      esac
    fi
  }
  compdef _wt wt 2>/dev/null
elif [ -n "$BASH_VERSION" ]; then
  _wt_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local subcmds="list ls add remove rm move lock unlock prune repair cd"
    local idxs
    idxs=$(_wt_entries | cut -d: -f1)
    if (( COMP_CWORD == 1 )); then
      COMPREPLY=($(compgen -W "$idxs $subcmds" -- "$cur"))
    else
      case ${COMP_WORDS[1]} in
        remove|rm|cd|move|lock|unlock)
          COMPREPLY=($(compgen -W "$idxs" -- "$cur")) ;;
      esac
    fi
  }
  complete -F _wt_complete wt
fi
