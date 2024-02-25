#!/bin/sh
github_username="ameer1234567890"
url_start="https://github.com/"

check_tools() {
  tools="curl git"
  for tool in $tools; do
    if [ ! "$(command -v "$tool")" ]; then
      printf "\e[1m%s\e[0m not found! Exiting....\n" "$tool"
      exit 1
    fi
  done
}

check_tools

cd "$(dirname "$0")" || exit
echo "Grabbing list of repositories...."
curl --progress-bar -o repos.json https://api.github.com/users/$github_username/repos
repos="$(grep -Po '"full_name":.*?[^\\]",' repos.json | awk '{print $2}' | tr -d '"' | tr -d ',')"
mkdir -p repos
cd repos || exit
for repo in $repos; do
  repo_name="$(echo "$repo" | cut -d '/' -f 2)"
  if [ ! -d "$repo_name" ]; then
    echo "Cloning new repository $repo_name...."
    git clone "$url_start$repo"
    status="$?"
  else
    echo "$repo_name already exists! Pulling any remote changes...."
    cd "$repo_name" || exit
    git pull --rebase
    status="$?"
    cd ..
  fi
  if [ "$status" != 0 ]; then
    printf "[\e[91mERROR\e[0m] Something went wrong!"
  else
    printf "[\e[32mINFO\e[0m] Done!"
  fi
  echo ""
done
cd ..
rm repos.json
echo "All repositories backed up!"
