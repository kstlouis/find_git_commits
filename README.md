# What is this? 

A simple `zsh` script that will take git commit `SHA`s as input and search for them in a User's directory. 

- Exits with code `0` if git is not installed (safe bet the repo's won't be there)
- Exits with code `0` if no repo's are found 
- Returns a list of all git repo's found then exits with code `0` if requested commits are not found 
- Returns list of commits and their metadata, then exits with code `1` if any are found. 

#  Caveats

- Written to be deployed via Jamf Pro. Uses Parameter 4. SHA's should be comma-separated, no spaces. 
- It will hammer disk I/O and cpu usage while it runs; up to a minutes. Narrow the search scope or run it off-hours.
- This was definitely vibe-coded. Use at your own risk. PRs welcome. 