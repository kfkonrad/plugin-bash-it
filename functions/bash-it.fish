function bash-it -d "My package"
  bash-it-$argv[1]
end

function bash-it-git_prompt_info
  bash-it _git-hide-status; and return
  set -g SCM_PREFIX
  set -g SCM_BRANCH
  set -g SCM_STATE
  set -g SCM_SUFFIX
  bash-it git_prompt_vars
  echo -e "$SCM_PREFIX""$SCM_BRANCH""$SCM_STATE""$SCM_SUFFIX"
end

##############################
### variables ################
##############################

if ! set -q SCM_CHECK
  set -g SCM_CHECK true
end

set -g SCM_THEME_PROMPT_DIRTY ' ✗'
set -g SCM_THEME_PROMPT_CLEAN ' ✓'
set -g SCM_THEME_PROMPT_PREFIX ' |'
set -g SCM_THEME_PROMPT_SUFFIX '|'
set -g SCM_THEME_BRANCH_PREFIX ''
set -g SCM_THEME_TAG_PREFIX 'tag:'
set -g SCM_THEME_DETACHED_PREFIX 'detached:'
set -g SCM_THEME_BRANCH_TRACK_PREFIX ' → '
set -g SCM_THEME_BRANCH_GONE_PREFIX ' ⇢ '
set -g SCM_THEME_CURRENT_USER_PREFFIX ' ☺︎ '
set -g SCM_THEME_CURRENT_USER_SUFFIX ''
set -g SCM_THEME_CHAR_PREFIX ''
set -g SCM_THEME_CHAR_SUFFIX ''

if ! set -q THEME_BATTERY_PERCENTAGE_CHECK
  set -g THEME_BATTERY_PERCENTAGE_CHECK true
end

if ! set -q SCM_GIT_SHOW_DETAILS
  set -g SCM_GIT_SHOW_DETAILS true
end
if ! set -q SCM_GIT_SHOW_REMOTE_INFO
  set -g SCM_GIT_SHOW_REMOTE_INFO auto
end
if ! set -q SCM_GIT_IGNORE_UNTRACKED
  set -g SCM_GIT_IGNORE_UNTRACKED false
end
if ! set -q SCM_GIT_SHOW_CURRENT_USER
  set -g SCM_GIT_SHOW_CURRENT_USER false
end
if ! set -q SCM_GIT_SHOW_MINIMAL_INFO
  set -g SCM_GIT_SHOW_MINIMAL_INFO false
end
if ! set -q SCM_GIT_SHOW_STASH_INFO
  set -g SCM_GIT_SHOW_STASH_INFO true
end
if ! set -q SCM_GIT_SHOW_COMMIT_COUNT
  set -g SCM_GIT_SHOW_COMMIT_COUNT true
end

set -g SCM_GIT 'git'
set -g SCM_GIT_CHAR '±'
set -g SCM_GIT_DETACHED_CHAR '⌿'
set -g SCM_GIT_AHEAD_CHAR "↑"
set -g SCM_GIT_BEHIND_CHAR "↓"
set -g SCM_GIT_AHEAD_BEHIND_PREFIX_CHAR " "
set -g SCM_GIT_UNTRACKED_CHAR "?:"
set -g SCM_GIT_UNSTAGED_CHAR "U:"
set -g SCM_GIT_STAGED_CHAR "S:"
set -g SCM_GIT_STASH_CHAR_PREFIX "{"
set -g SCM_GIT_STASH_CHAR_SUFFIX "}"
set -g GIT_THEME_PROMPT_PREFIX ' ('
set -g GIT_THEME_PROMPT_SUFFIX ')'

##############################
### git helpers ##############
##############################

function bash-it-_git-hide-status
  test "(git config --get bash-it.hide-status)" = "1"
end

function bash-it-_git-branch
  git symbolic-ref -q --short HEAD 2> /dev/null || return 1
end

function bash-it-_git-friendly-ref
  bash-it _git-branch || bash-it _git-tag || bash-it _git-commit-description || bash-it _git-short-sha
end

function bash-it-_git-tag
  git describe --tags --exact-match 2> /dev/null
end

function bash-it-_git-commit-description
  git describe --contains --all 2> /dev/null
end

function bash-it-_git-short-sha
  git rev-parse --short HEAD
end

function bash-it-_git-symbolic-ref
  git symbolic-ref -q HEAD 2> /dev/null
end

function bash-it-_git-upstream
  set -l ref
  set ref (bash-it _git-symbolic-ref) || return 1
  git for-each-ref --format="%(upstream:short)" "$ref"
end

function bash-it-_git-upstream-branch
  set -l ref
  set ref (bash-it _git-symbolic-ref) || return 1

  # git versions < 2.13.0 do not support "strip" for upstream format
  # regex replacement gives the wrong result for any remotes with slashes in the name,
  # so only use when the strip format fails.
  git for-each-ref --format="%(upstream:strip=3)" "$ref" 2> /dev/null || git for-each-ref --format="%(upstream)" "$ref" | sed -e "s/.*\/.*\/.*\///"
end

function bash-it-_git-num-remotes
  git remote | wc -l
end

function bash-it-_git-upstream-remote
  set -l upstream
  set upstream (bash-it _git-upstream) || return 1

  set -l branch
  set branch (bash-it _git-upstream-branch) || return 1
  echo "$upstream" | sed "s|/$branch||"
end

function bash-it-_git-upstream-branch-gone
  test ""(git status -s -b | sed -e 's/.* //' | head -n1) = "[gone]"
end

### WIP ###

function bash-it-_git-remote-info
  # this catches empty strings
  #test (echo(echo bash-it _git-upstream)) = "" && return || true
  set -l same_branch_name
  test (bash-it _git-branch) = (echo (bash-it _git-upstream-branch)) && set same_branch_name true || true
  test (bash-it _git-branch) = (echo (bash-it _git-upstream-branch)) && set same_branch_name true
  return

  if test "$SCM_GIT_SHOW_REMOTE_INFO" = "auto" && test (bash-it _git-num-remotes) -ge 2 ||
      test "$SCM_GIT_SHOW_REMOTE_INFO" = "true"
    if test "$same_branch_name" != "true"
      set remote_info (bash-it _git-upstream)
    else
      set remote_info (bash-it _git-upstream-remote)
    end
  else if test "$same_branch_name" != "true"
    set remote_info (bash-it _git-upstream-branch)
  end
  if test -n "$remote_info"
    set -l branch_prefix
    if bash-it _git-upstream-branch-gone
      set branch_prefix "$SCM_THEME_BRANCH_GONE_PREFIX"
    else
      set branch_prefix "$SCM_THEME_BRANCH_TRACK_PREFIX"
    end
    echo "$branch_prefix""$remote_info"
  end
end

function bash-it-_git-upstream-behind-ahead
  git rev-list --left-right --count (bash-it _git-upstream)"...HEAD" 2> /dev/null
end

function bash-it-_git-status
  set -l git_status_flags
  test "$SCM_GIT_IGNORE_UNTRACKED" = "true" && set git_status_flags '-uno' || true
  git status --porcelain $git_status_flags 2> /dev/null
end

function bash-it-_git-status-counts
  bash-it _git-status | awk '
  BEGIN {
    untracked=0;
    unstaged=0;
    staged=0;
  }
  {
    if ($0 ~ /^\?\? .+/) {
      untracked += 1
    } else {
      if ($0 ~ /^.[^ ] .+/) {
        unstaged += 1
      }
      if ($0 ~ /^[^ ]. .+/) {
        staged += 1
      }
    }
  }
  END {
    print untracked "\t" unstaged "\t" staged
  }'
end

function bash-it-git_user_info
  # support two or more initials, set by 'git pair' plugin
  set -l SCM_CURRENT_USER (git config user.initials | sed 's% %+%')
  # if `user.initials` weren't set, attempt to extract initials from `user.name`
  test -z "$SCM_CURRENT_USER" && set SCM_CURRENT_USER (printf "%s" (for word in (git config user.name | env PERLIO=:utf8 perl -pe '$_=lc'); printf "%s" (if test "$word" = '0'; echo 0; else; echo 1; end); end))
  test -n "$SCM_CURRENT_USER" && printf "%s" "$SCM_THEME_CURRENT_USER_PREFFIX""$SCM_CURRENT_USER""$SCM_THEME_CURRENT_USER_SUFFIX"
end

############################################################
### main function ##########################################
############################################################

function bash-it-git_prompt_vars
  if bash-it _git-branch > /dev/null
    set -l SCM_GIT_DETACHED "false"
    set SCM_BRANCH "$SCM_THEME_BRANCH_PREFIX"(bash-it _git-friendly-ref)(bash-it _git-remote-info;echo)
  else
    set SCM_GIT_DETACHED "true"
    set -l detached_prefix
    if bash-it _git-tag > /dev/null
      set detached_prefix $SCM_THEME_TAG_PREFIX
    else
      set detached_prefix $SCM_THEME_DETACHED_PREFIX
    end
    set SCM_BRANCH "$detached_prefix"(bash-it _git-friendly-ref)
  end

  set -l commits_behind_ahead (bash-it _git-upstream-behind-ahead)
  set -l commits_behind (echo $commits_behind_ahead | awk '{print $1}')
  set -l commits_ahead (echo $commits_behind_ahead | awk '{print $2}')

  if test -n "$commits_ahead" -a "$commits_ahead" -gt 0
    set SCM_BRANCH "$SCM_BRANCH""$SCM_GIT_AHEAD_BEHIND_PREFIX_CHAR""$SCM_GIT_AHEAD_CHAR"
    test "$SCM_GIT_SHOW_COMMIT_COUNT" = "true" && set SCM_BRANCH "$SCM_BRANCH""$commits_ahead"
  end

  if test -n "$commits_behind" -a "$commits_behind" -gt 0
    set SCM_BRANCH "$SCM_BRANCH""$SCM_GIT_AHEAD_BEHIND_PREFIX_CHAR""$SCM_GIT_BEHIND_CHAR"
    test "$SCM_GIT_SHOW_COMMIT_COUNT" = "true" && set SCM_BRANCH "$SM_BRANCH""$commits_behind"
  end

  if test "$SCM_GIT_SHOW_STASH_INFO" = "true"
    set -l stash_count
    set stash_count (git stash list 2> /dev/null | wc -l | tr -d ' ')
    test "$stash_count" -gt 0 && set SCM_BRANCH "$SCM_BRANCH"" $SCM_GIT_STASH_CHAR_PREFIX""$stash_count""$SCM_GIT_STASH_CHAR_SUFFIX"
  end

  if set -q GIT_THEME_PROMPT_CLEAN
    set SCM_STATE $GIT_THEME_PROMPT_CLEAN
  else
    set SCM_STATE $SCM_THEME_PROMPT_CLEAN
  end

  if ! bash-it _git-hide-status
    set -l status_counts (bash-it _git-status-counts)
    set -l untracked_count (echo $status_counts | awk '{print $1}')
    set -l unstaged_count (echo $status_counts | awk '{print $2}')
    set -l staged_count (echo $status_counts | awk '{print $3}')

    if test "$untracked_count" -gt 0 -o "$unstaged_count" -gt 0 -o "$staged_count" -gt 0
      set SCM_DIRTY 1
      if test "$SCM_GIT_SHOW_DETAILS" = "true"
        test "$staged_count" -gt 0    && set SCM_BRANCH "$SCM_BRANCH"" $SCM_GIT_STAGED_CHAR""$staged_count"       && set SCM_DIRTY 3
        test "$unstaged_count" -gt 0  && set SCM_BRANCH "$SCM_BRANCH"" $SCM_GIT_UNSTAGED_CHAR""$unstaged_count"   && set SCM_DIRTY 2
        test "$untracked_count" -gt 0 && set SCM_BRANCH "$SCM_BRANCH"" $SCM_GIT_UNTRACKED_CHAR""$untracked_count" && set SCM_DIRTY 1
      end

      if set -q GIT_THEME_PROMPT_DIRTY
        set SCM_STATE $GIT_THEME_PROMPT_DIRTY
      else
        set SCM_STATE $SCM_THEME_PROMPT_DIRTY
      end
    end
  end

  test "$SCM_GIT_SHOW_CURRENT_USER" = "true" && set SCM_BRANCH "$SCM_BRANCH"(bash-it git_user_info)

  if set -q GIT_THEME_PROMPT_PREFIX
    set -x SCM_PREFIX $GIT_THEME_PROMPT_PREFIX
  else
    set -x SCM_PREFIX $SCM_THEME_PROMPT_PREFIX
  end

  if set -q GIT_THEME_PROMPT_SUFFIX
    set SCM_SUFFIX $GIT_THEME_PROMPT_SUFFIX
  else
    set SCM_SUFFIX $SCM_THEME_PROMPT_SUFFIX
  end

  set SCM_CHANGE (bash-it _git-short-sha 2>/dev/null || echo "")
end
