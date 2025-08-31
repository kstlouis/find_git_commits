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

# 1) Check if git is installed
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

# 2) Get current logged-in user (so we're not running git commands as root) and home dir path
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

# 3) Locate git repositories (prints parent path of .git)
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

# 4) make a hash array of commits (should be comma separated)
# ==================================================================================
#FOR LOCAL TESTING: 
# comment out this line 
# then uncomment the array. Insert your own hashes.
# ==================================================================================
hashes=("${(@s/,/)4}")
# hashes=(
#   848cf4aa23c9ed6c8bb1aa4ecbec800aa94e638b
#   26bf9fa35dcc36fa1e8eb5f9624eaba46ad6d38a)

# 5) Search each provided SHA across all repos
matches_found=0

for sha in "${hashes[@]}"; do
  echo "Looking for $sha..."
  for repo in "${repos[@]}"; do
    if sudo -u "$currentUser" git -C "$repo" rev-parse --quiet --verify "${sha}^{commit}" >/dev/null 2>&1; then
      full_sha=$(sudo -u "$currentUser" git -C "$repo" rev-parse "${sha}^{commit}")
      echo "  FOUND! sha=$full_sha"
      echo "  repo=$repo"
      echo ""
      matches_found=1
    fi
  done
done

if (( matches_found == 0 )); then
  echo "no matching commits found"
  exit 0
fi

exit 1