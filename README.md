# What is this? 

A simple `zsh` script that will take git commit `SHA`s as input and search for them in a User's directory. 

- Exits with code `0` if git is not installed (safe bet the repo's won't be there)
- Exits with code `0` if no repo's are found 
- Returns a list of all git repo's found then exits with code `0` if requested commits are not found 
- Returns list of commits and their metadata, then exits with code `1` if any are found. 