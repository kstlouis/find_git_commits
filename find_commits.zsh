#!/bin/zsh

# =========================================
# git repo + commit finder (macOS / zsh)
# Usage:
#   ./find_commits.zsh                 # list repos only
#   ./find_commits.zsh <sha> [<sha>...] # search SHAs across repos
# =========================================

# 1) Check if git is installed
# macOS by default comes with a stubbed git command that triggers CLT install; checking "command -v git" isnt' sufficient. 

# Check for a Homebrew git first:
for p in /opt/homebrew/bin/git /usr/local/bin/git /opt/local/bin/git; do
  if [[ -x "$p" ]]; then
    echo "Homebrew git installed: $p"
  fi
done

# Check if Xcode/CLT is configured (silent, no prompt)
if /usr/bin/xcode-select -p >/dev/null 2>&1; then
  # Safe to use xcrun now; this won't prompt since tools are present
  if /usr/bin/xcrun --find git >/dev/null 2>&1; then
    echo "Xcode CLT git installed:"
  fi
fi

echo "No git install found."
exit 0

# 2) Console user & home (per your snippet)
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
echo "Current logged-in user: $currentUser"

if [[ -z "${currentUser:-}" ]]; then
  echo "No console user detected; exiting 0"
  exit 0
fi

userHome="/Users/$currentUser"
if [[ ! -d "$userHome" ]]; then
  echo "Home directory not found for '$currentUser' ($userHome); exiting 0"
  exit 0
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

# If no SHAs provided, just list repos and exit 0.
if [[ -z "$4" ]]; then
  printf "%s\n" "${repos[@]}"
  exit 0
fi

# 4) make a hash array of commits (should be comma separated)
hashes=("${(@s/,/)4}")
#for testing:
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