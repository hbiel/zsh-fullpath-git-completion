__git_files () {
  local compadd_opts opts tag description gittoplevel gitprefix files expl

  zparseopts -D -E -a compadd_opts V+: J+: 1 2 o+: n f x+: X+: M+: P: S: r: R: q F:
  zparseopts -D -E -a opts -- -cached -deleted -modified -others -ignored -unmerged -killed x+: --exclude+:
  tag=$1 description=$2; shift 2

  gittoplevel=$(_call_program toplevel git rev-parse --show-toplevel 2>/dev/null)
  __git_command_successful $pipestatus || return 1
  [[ -n $gittoplevel ]] && gittoplevel+="/"

  gitprefix=$(_call_program gitprefix git rev-parse --show-prefix 2>/dev/null)
  __git_command_successful $pipestatus || return 1

  # TODO: --directory should probably be added to $opts when --others is given.

  local pref=${(Q)${~PREFIX}}
#  [[ $pref[1] == '/' ]] || pref=$gittoplevel$gitprefix$pref
[[ $pref[1] == '/' ]] || pref=$gittoplevel$pref # change: show files based on project root instead of current dir (prefix)

  # First allow ls-files to pattern-match in case of remote repository. Use the
  # icase pathspec magic word to ensure that we support case-insensitive path
  # completion for users with the appropriate matcher configuration
  files=(${(0)"$(_call_program files git ls-files -z --exclude-standard ${(q)opts} -- ${(q)${pref:+:\(icase\)$pref\*}:-.} 2>/dev/null)"})
  __git_command_successful $pipestatus || return

  # If ls-files succeeded but returned nothing, try again with no pattern. Note
  # that ls-files defaults to the CWD if not given a path, so if the file we
  # were trying to add is in an *adjacent* directory, this won't return anything
  # helpful either
  if [[ -z "$files" && -n "$pref" ]]; then
    files=(${(0)"$(_call_program files git ls-files -z --exclude-standard ${(q)opts} -- 2>/dev/null)"})
    __git_command_successful $pipestatus || return
  fi

#  _wanted $tag expl $description _files -g '{'${(j:,:)files}'}' $compadd_opts -
#  _wanted $tag expl $description _multi_parts -f $compadd_opts - / files
  _wanted $tag expl $description compadd -f $compadd_opts -a files # change: add full path of all file candidates instead of in _multi_parts
}

__git_diff-index_files () {
  local tree=$1 description=$2 tag=$3; shift 3
  local files expl

  # $tree needs to be escaped for _call_program; matters for $tree = "HEAD^"
  files=$(_call_program files git diff-index -z --name-only --no-color --cached ${(q)tree} 2>/dev/null)
  __git_command_successful $pipestatus || return 1
  files=(${(0)"$(__git_files_relative $files)"})
  __git_command_successful $pipestatus || return 1

#  _wanted $tag expl $description _multi_parts $@ - / files
  _wanted $tag expl $description compadd -f $compadd_opts -a files # change: add full path of all file candidates instead of in _multi_parts
}

__git_changed-in-working-tree_files () {
  local files expl

  files=$(_call_program changed-in-working-tree-files git diff -z --name-only --no-color 2>/dev/null)
  __git_command_successful $pipestatus || return 1
  files=(${(0)"$(__git_files_relative $files)"})
  __git_command_successful $pipestatus || return 1

#  _wanted changed-in-working-tree-files expl 'changed in working tree file' _multi_parts $@ -f - / files
  _wanted changed-in-working-tree-files expl 'changed in working tree file' compadd -f $compadd_opts -a files # change: add full path of all file candidates instead of in _multi_parts
}

#     __git_tree_files [--root-relative] FSPATH TREEISH [TREEISH...] [COMPADD OPTIONS]
#
# Complete [presently: a single level of] repository files under FSPATH.
# FSPATH is interpreted as a directory path within each TREEISH.
# FSPATH is relative to cwd, unless --root-relative is specified, in
# which case it is relative to the repository root.
__git_tree_files () {
  local tree Path
  integer at_least_one_tree_added
  local -a tree_files compadd_opts
  local -a extra_args

  if [[ $1 == --root-relative ]]; then
    extra_args+=(--full-tree)
    shift
  fi

  zparseopts -D -E -a compadd_opts V+: J+: 1 2 o+: n f x+: X+: M+: P: S: r: R: q F:

  Path=${(M)1##(../)#}
  [[ ${1##(../)#} = */* ]] && extra_args+=( -r )
  shift
  (( at_least_one_tree_added = 0 ))
  for tree; do
    tree_files+=(${(ps:\0:)"$(_call_program tree-files git ls-tree $extra_args --name-only -z ${(q)tree} $Path 2>/dev/null)"})
    __git_command_successful $pipestatus && (( at_least_one_tree_added = 1 ))
  done

  if (( !at_least_one_tree_added )); then
    return 1
  fi

  local expl
#  _wanted files expl 'tree file' _multi_parts -f $compadd_opts -- / tree_files
  _wanted files expl 'tree file' compadd -f $compadd_opts -a files # change: add full path of all file candidates instead of in _multi_parts
}
