#!/bin/zsh

# =========================================
# script for finding .git commits by specific hashes. 
# Usage:
#   ./find_commits.zsh                  # only return list of repos
#   ./find_commits.zsh <sha1,sha2,sha3> # search for commits in any repos, returns full path to commit hash
#  
# Note: meant to be deployed through Jamf with arguments provided as parameters.
# For local testing, some modification is required.
# =========================================

# Input parameters:

# $4: commit hashes. Comma-Separated <sha1,sha2,sha3?
# ==================================================================================
#FOR LOCAL TESTING: 
# comment out this line then uncomment the array. Insert your own hashes.
# ==================================================================================
hashes=("${(@s/,/)4}")
# hashes=(
#   sha1
#   sha2)
#
# $5: usage mode. "report-only" or "remove" (default is report-only)
remove=false
# ==================================================================================
#FOR LOCAL TESTING: 
# comment out the if/else block and just edit "remove" manually
# ==================================================================================
if [[ "$5" == "remove" ]]; then
  remove=true
  echo "Running in REMOVE mode..."
else
  echo "Running in REPORT-ONLY mode..."
fi

# Exit if array is empty (no commit hashes entered)
if [[ ${#hashes[@]} -eq 0 ]]; then
  echo "Error: no commit hashes provided."
  exit 2
fi

# Check if git is installed
# if git isn't installed, script exits. Assumption is no git --> no git repositories.
# macOS by default comes with a stubbed git command that triggers CLT install; checking "command -v git" isnt' sufficient. 

# check brew first:
if [[ -x /opt/homebrew/bin/git || -x /usr/local/bin/git || -x /opt/local/bin/git ]]; then
  for p in /opt/homebrew/bin/git /usr/local/bin/git /opt/local/bin/git; do
    if [[ -x "$p" ]]; then
      echo "git installed at: $p"
      break
    fi
  done
  # check for xcode CLT install (with some tricks to make it silent)
elif /usr/bin/xcode-select -p >/dev/null 2>&1 && /usr/bin/xcrun --find git >/dev/null 2>&1; then
  echo "git installed at: $(/usr/bin/xcrun --find git)"
else
  echo "Git not installed"
  exit 0
fi

# Get current logged-in user (so we're not running git commands as root) and home dir path
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
echo "Current logged-in user: $currentUser"

if [[ -z "${currentUser:-}" ]]; then
  echo "No console user detected; exiting 0"
  exit 2
fi

userHome="/Users/$currentUser"
if [[ ! -d "$userHome" ]]; then
  echo "Home directory not found for '$currentUser' ($userHome); exiting 0"
  exit 2
fi

# Locate git repositories (prints parent path of .git)
echo "Searching for git repositories in $userHome..."

repos=()

# Use find with -print0 for safety with spaces
while IFS= read -r -d '' repo; do
  # Strip trailing "/.git"
  parent="${repo%/.git}"
  repos+=("$parent")
done < <(
  find "$userHome" \
    -type d -name ".git" \
    -not -path "*/Library/*" \
    -not -path "*/.Trash/*" \
    -not -path "*/.cache/*" \
    -prune \
    -print0 2>/dev/null
)

# Search each provided SHA across all repos

# Ensure zsh unique-array behavior
typeset -aU matches_found     # unique elements only
matches_found=()              # start empty

for sha in "${hashes[@]}"; do
  echo "Looking for $sha..."
  for repo in "${repos[@]}"; do
    if sudo -u "$currentUser" git -C "$repo" rev-parse --quiet --verify "${sha}^{commit}" >/dev/null 2>&1; then
      full_sha=$(sudo -u "$currentUser" git -C "$repo" rev-parse "${sha}^{commit}")
      echo "  FOUND! sha=$full_sha"
      echo "  repo=$repo"
      echo ""
      matches_found+=("$repo")   # add repo; dedup handled by -aU
    fi
  done
done

# If no matches, array will still be empty
if [[ ${#matches_found[@]} -eq 0 ]]; then
  echo "no matching commits found"
  exit 0
else
  if $remove; then
    echo "Matches found. REMOVE mode: cleaning unreachable objects in matched repos..."
    for repo in "${matches_found[@]}"; do
      echo "  Cleaning: $repo"
      # cd into each repo as the target user, then run the maintenance commands
      if ! sudo -u "$currentUser" bash -c 'cd "$1" && git reflog expire --expire-unreachable=now --all && git gc --prune=now' _ "$repo"; then
        echo "  ERROR: Cleanup failed in $repo"
        exit 1
      fi
    done
    exit 0
  else
    echo "Matches found. REPORT-ONLY mode: no changes made."
  fi
fi

exit 1