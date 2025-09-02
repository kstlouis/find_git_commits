# What is this? 

A simple `zsh` script that will take git commit hashes as input and search for them in a User's directory. 

Soomewhat confusingly, it will exit with an error code `1` if it _does_ find the requested commit hashes. This is to make it easier to use in an MDM environment.

- Exits with code `0` if git is not installed (no git == likely no repositories)
- Exits with code `0` if no git repositories are found 
- Returns list of commits and their metadata, then exits with code `1` if any are found (or if any other error occurs)

# Usage

This script deploys with 2 arguments/parameters: 

`$4`: commit `SHA` values we're looking for. Provide them all at once, comma-separated (`sha1,sha2,sha3`)
`$5`: deployment mode. `report-only` or `remove`. If no argument is provided, report-only is the default.

For the safest/cleanest experience, use both modes in series.

### 1. `Report-only` mode

- deploy via MDM to desired endpoints using a Policy
- review all `failed` results; address any unknown errors, then flush the fail log for that unit so the policy re-deploys.

### 2. `Remove` mode \[still WIP\]

When _only_ affected devices are left in `failed` reporting:
- adjust `$5` so removal mode is triggered
- flush all failed runs from the Policy logs so the Policy re-deploys
- if cleanup is successful, no `failed` devices should remain in the policy logs!


#  Caveats

- Written to be deployed via Jamf Pro. Uses Parameter 4. SHA's should be comma-separated, no spaces. 
- It will hammer disk I/O and cpu usage while it runs; up to a minutes. Narrow the search scope or run it off-hours.
- This was definitely vibe-coded. Use at your own risk. PRs welcome. 

# Local Testing

If you want to test locally, `$4` and `$5` need to be modified in the script to accept local arguments, or just comment out the appropriate sections. 

you can make a test repo to check commit removal with the following: 

```
# 1) New test repo
mkdir /tmp/git-dangle-test && cd /tmp/git-dangle-test
git init
git commit --allow-empty -m "root"

# 2) Create commits on a throwaway branch
git checkout -b throwaway
echo a > f && git add f && git commit -m "add f"
echo b >> f && git commit -am "change f"

# 3) Delete the branch (these commits become unreachable/dangling)
git checkout - # back to main/master
git branch -D throwaway

# 4) Confirm dangling commits exist
git fsck --dangling    # should print lines like: "dangling commit <sha>"
```

# Future Improvements

- ~~remove component that just lists found repositories. useful for testing but extraneous.~~
- ~~clean up order of operations, put args/parameters near top~~
- ~~add mode switcher; with arguments given to `$5`, list-only mode vs "search and destroy" cleanup mode~~
  - ~~list-only still exits with code 1 when hashes are detected~~
  - ~~cleanup mode will exit 0 on success~~
- add ability to limit search to only specific directories
  - entire User dir is needlessly invasive and costs a lot of cpu & I/O
