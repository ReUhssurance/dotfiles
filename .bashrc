# Compares current branch against 'dev' branch to see what commits
# are not in both places.  Supply a branch name as an argument if you would
# like to compare against another upstream branch
function git_upstream() {
  upstream_branch=${1:-dev}
  echo "Branch \e[31m$(git rev-parse --abbrev-ref HEAD)\e[39m is \e[33m$(git rev-list --count ${upstream_branch}..) commits\e[39m ahead and \e[33m$(git rev-list --count ..${upstream_branch}) commits\e[39m behind \e[31m${upstream_branch}\e[39m"
}


# Setup employer specific environment
COMPANY_FILE="$HOME/.companyrc"
if [ -f $COMPANY_FILE ]; then
  . $COMPANY_FILE
fi
