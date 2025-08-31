# What is this? 

A simple `zsh` script that will take git commit hashes as input and search for them in a User's directory. 

- Exits with code `0` if git is not installed (no git == likely no repositories)
- Exits with code `0` if no git repositories are found 
- Returns list of commits and their metadata, then exits with code `1` if any are found. 

#  Caveats

- Written to be deployed via Jamf Pro. Uses Parameter 4. SHA's should be comma-separated, no spaces. 
- It will hammer disk I/O and cpu usage while it runs; up to a minutes. Narrow the search scope or run it off-hours.
- This was definitely vibe-coded. Use at your own risk. PRs welcome. 

# Future Improvements

- ~~remove component that just lists found repositories. useful for testing but extraneous.~~
- clean up order of operations, put args/parameters near top
- add ability to limit search to only specific directories
  - entire User dir is needlessly invasive and costly
- add mode switcher; with arguments given to `$5`, list-only mode vs "search and destroy" cleanup mode
  - list-only still exits with code 1 when hashes are detected
  - cleanup mode will exit 0 on success