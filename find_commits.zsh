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
# -prune keeps traversal fast and avoids descending into .git internals repeatedly
git_dirs=($(find "$userHome" -type d -name ".git" -prune 2>/dev/null))

if (( ${#git_dirs[@]} == 0 )); then
  echo "no git repos found"
  exit 0
fi

# Convert .git paths to repo roots
repos=()
for d in "${git_dirs[@]}"; do
  repos+=("${d%/.git}")
done

# If no SHAs provided, just list repos and exit 0.
# if [[ -z "$4" ]]; then
#   printf "%s\n" "${repos[@]}"
#   exit 0
# fi

# 4) make a hash array of commits (should be comma separated)
#hashes=(${4//,/ })
hashes="848cf4aa23c9ed6c8bb1aa4ecbec800aa94e638b"

# 5) Search each provided SHA across all repos
echo "searching for commits: ${hashes[@]}"
matches_found=0

for sha in "${hashes[@]}"; do
  for repo in "${repos[@]}"; do
    # Quietly verify the SHA resolves to a commit in this repo (short SHAs OK if unique)
    if git -C "$repo" rev-parse --quiet --verify "${sha}^{commit}" >/dev/null 2>&1; then
      full_sha=$(git -C "$repo" rev-parse "${sha}^{commit}" 2>/dev/null)
      # Gather a few useful fields about the commit
      subject=$(git -C "$repo" log -1 --format='%s' "$full_sha" 2>/dev/null)
      author=$(git -C "$repo" log -1 --format='%an <%ae>' "$full_sha" 2>/dev/null)
      date=$(git -C "$repo" log -1 --format='%ci' "$full_sha" 2>/dev/null)
      remote=$(git -C "$repo" remote get-url origin 2>/dev/null || true)

      echo "  FOUND: sha=$full_sha"
      echo "  repo=$repo"
      [[ -n "$remote" ]] && echo "  remote=$remote"
      echo "  date=$date"
      echo "  author=$author"
      echo "  subject=$subject"
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