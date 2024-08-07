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

start_t=$(date +%s)
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
end_t=$(date +%s)
run_t=$(expr "$end_t" - "$start_t")
run_t=$(expr "$run_t" \* 1000)
if [ "$exit_code_sum" != 0 ]; then
  curl -k "https://printer.lan:5001/api/push/dqSekPDUWh?status=down&msg=Error:+$exit_code_sum&ping=$run_t"
  exit 1
else
  curl -k "https://printer.lan:5001/api/push/dqSekPDUWh?status=up&msg=OK&ping=$run_t"
fi
