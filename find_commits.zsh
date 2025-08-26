#!/bin/zsh

# =========================================
# git repo + commit finder (macOS / zsh)
# Usage:
#   ./find_commits.zsh                 # list repos only
#   ./find_commits.zsh <sha> [<sha>...] # search SHAs across repos
# =========================================

# 1) Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "git not installed"
  exit 0
fi

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
# for testing:
# hashes=(
#   848cf4aa23c9ed6c8bb1aa4ecbec800aa94e638b
#   26bf9fa35dcc36fa1e8eb5f9624eaba46ad6d38a)

# 5) Search each provided SHA across all repos
matches_found=0
matched_repos=()

  for sha in "${hashes[@]}"; do
    echo "Looking for $sha..."
    for repo in "${repos[@]}"; do
    if sudo -u "$currentUser" git -C "$repo" rev-parse --quiet --verify "${sha}^{commit}" >/dev/null 2>&1; then
        full_sha=$(sudo -u "$currentUser" git -C "$repo" rev-parse "${sha}^{commit}")
        echo "  FOUND! sha=$full_sha"
        echo "  repo=$repo"
        echo ""
        matches_found=1
        # Add repo to matched_repos array if not already present
        if [[ ! " ${matched_repos[*]} " =~ " $repo " ]]; then
            matched_repos+=("$repo")
        fi
    fi
  done
done

if (( matches_found == 0 )); then
  echo "no matching commits found"
  exit 0
fi

# 6) Search each repo in matched_repos for refs that contain each found commit
for repo in "${matched_repos[@]}"; do
  echo "Searching for refs in $repo..."
  refs=$(sudo -u "$currentUser" git -C "$repo" for-each-ref --contains "$full_sha" --format='%(refname:short)' 2>/dev/null)
  if [[ -n "$refs" ]]; then
    echo "  refs containing this commit:"
    while IFS= read -r ref; do
      echo "    $ref"
    done <<< "$refs"
    exit 0
  else
    echo "  no refs found containing this commit"
    exit 1
  fi
done

exit 1