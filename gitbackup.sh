#!/bin/sh
github_username="ameer1234567890"
url_start="https://github.com/"
exit_code_sum=0

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
exit_code_sum=$((exit_code_sum + $?))
repos="$(grep -Po '"full_name":.*?[^\\]",' repos.json | awk '{print $2}' | tr -d '"' | tr -d ',')"
mkdir -p repos
exit_code_sum=$((exit_code_sum + $?))
cd repos || exit
for repo in $repos; do
  repo_name="$(echo "$repo" | cut -d '/' -f 2)"
  if [ ! -d "$repo_name" ]; then
    echo "Cloning new repository $repo_name...."
    git clone "$url_start$repo"
    exit_code_sum=$((exit_code_sum + $?))
  else
    echo "$repo_name already exists! Pulling any remote changes...."
    cd "$repo_name" || exit
    git pull --rebase
    exit_code_sum=$((exit_code_sum + $?))
    cd ..
  fi
  echo ""
done
cd ..
rm repos.json
exit_code_sum=$((exit_code_sum + $?))
if [ "$exit_code_sum" != 0 ]; then
  printf "[\e[91mERROR\e[0m] Something went wrong!"
else
  printf "[\e[32mINFO\e[0m] All repositories backed up!"
fi
