# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"


plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

alias vim="(pyenv activate $(cat .python-version &>/dev/null)) || true && nvim"
alias kvim='NVIM_APPNAME="nvim-kickstart" nvim'
alias k="kubectl"
alias dc="docker compose"

srcenv() {
  # Local .env
  if [ -f .env ]; then
    # Load Environment Variables
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
  fi
}

mrg() {
  rg $1 . $(python -c 'import site; print(site.getsitepackages()[0])')
}

whatsdeployed() {
  IMAGE=$(kubectl -o json get deployment --context prd --namespace consumer monolith-spothero-django | jq -r '.spec.template.spec.containers[] | select(.name == "monolith-spothero-django") | .image')
  IFS='-' read -r -A IMAGE_PARTS <<< "${IMAGE}"
  COMMIT_SHA="${IMAGE_PARTS[5]}"

  echo "https://github.com/spothero/SpotHero-Django/commit/${COMMIT_SHA}"
}

kcron () {
  kubectl get pod --sort-by=.status.startTime --all-namespaces | grep $2 | tail -n 1 | awk '{system("kubectl logs -n "$1" "$2)}'
}

function set-django-pr-pipe() {
    bin/showpipe consumer spothero-django &>/dev/null && \
    while true; do fly -t consumer sp -p spothero-django-prs --instance-var number=$1 -c - < pr-pipeline.norender.yaml; sleep 5; done
}

function pr-test-failures() {
    fly -t consumer builds -j spothero-django-prs/number:$1/test-pull-request | rg -m 1 failed | choose 0 | rush -- "fly -t consumer watch -b {} |  rg -o '(FAIL|ERROR): (\w+) \((.*)\)'" | sort | uniq
}

function mypy-by() {
  write_to_file="false"
  diff="false"
  directory="."
  error_code="false"
  while [[ $# -gt 0 ]]; do
    case $1 in
      --error-code)
        error_code="$2"
        shift
        shift
        ;;
      --dir)
        directory="$2"
        shift
        shift
        ;;
      --diff)
        diff="true"
        shift
        ;;
      --write-to-file)
        write_to_file="true"
        shift
        ;;
      -*|--*)
        echo "unknown option $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "$error_code" ]]; then
    echo "must specify an error code, for example mypy-by-type unused-ignore"
    exit 1
  fi
  mypy_args=("--" "$directory")
  rg_args=("error:\\s.*\\[$error_code\\]$")

  error_code_file_token=""
  if [[ "$error_code" != "false" ]]; then
    error_code_file_token=".${error_code}"
  fi
  dir_file_token=""
  if [[ "$directory" != "." ]]; then
    dir_file_token=".dir"
  fi
  output_file="mypy${error_code_file_token}${dir_file_token}.log"
  if [[ "$write_to_file" == "true" ]]; then
    if [[ "$diff" == "true" ]]; then
      echo "--write-to-file and --diff cannot be used together"
      exit 1;
    fi
    dmypy run "${mypy_args[@]}" | rg "${rg_args[@]}" | sort > "$output_file"
    echo "Wrote $(wc -l < $output_file | xargs) lines to $output_file"
  elif [[ "$diff" == "true" ]]; then
    diff -c "$output_file" <(dmypy run "${mypy_args[@]}" | rg "${rg_args[@]}" | sort) --color=always | less
  else
    rg_args+=("--color" "always")
    dmypy run "${mypy_args[@]}" | rg "${rg_args[@]}" | sort
  fi
}

function codeowner-prs() {
  gh api graphql -f query='
  query {
    repository(owner: "spothero", name: "spothero-django") {
      pullRequests(last: 50, states: OPEN) {
        nodes {
          author {
            login
          }
          isDraft
          number
          title
          url
          reviewRequests(first: 10) {
            nodes {
              requestedReviewer {
                ... on Team {
                  slug
                  name
                }
              }
            }
          }
          commits(last: 1) {
            nodes {
              commit {
                statusCheckRollup {
                  contexts(first: 100) {
                    nodes {
                      ... on StatusContext {
                        context
                        state
                        targetUrl
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }' | jq '.data.repository.pullRequests.nodes[] as $pr |
  select($pr.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]? |
    select(.context == "concourse-ci/optin-codeowner-approval" and .state == "FAILURE")
  ) |
  {
    title: $pr.title,
    author: $pr.author.login,
    number: $pr.number,
    url: $pr.url,
    isDraft: $pr.isDraft,
    checkUrl: ($pr.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[] | 
               select(.context == "concourse-ci/optin-codeowner-approval") | .targetUrl),
    reviewers: [$pr.reviewRequests.nodes[] | .requestedReviewer.slug | select(. != null)]
  }'
}

function reviews() {
  TEAM=${1:-monolith-platform}
  # Colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
  echo
  codeowner-prs | jq -r --arg TEAM "$TEAM" '. | select(.reviewers | any(. == $TEAM)) | "\(.title)|\(.url)|\(.author)|\(.checkUrl)"' |
  while IFS='|' read -r title url author check_url; do
      printf "${BOLD}%s${NC}\n" "$title"
      printf "   \uf415 ${BLUE}%s${NC}\n" "$author"
      printf "   \uea64 ${BLUE}%s${NC}\n" "$url"
      printf "   \uf49e ${BLUE}%s${NC}\n" "$check_url"
      echo
  done
}


# pg() {
#   emulate -L zsh          # localise zsh options, keep your login shell safe
#   setopt kshcoprocess     # turn on Bash/ksh-style coprocesses
#   set -euo pipefail
#
#   DB_ALIAS=${1:?usage: pg <prd>}
#   case $DB_ALIAS in
#     prd)
#       DB=prd-monolith-reader
#       DB_NAME=spothero_production
#       DB_USER=teleport_reader
#       ;;
#     *)
#       print -u2 "Unknown database – try: tsh db ls"
#       return 1
#       ;;
#   esac
#
#   tsh db login "$DB" --db-name="$DB_NAME" --db-user="$DB_USER"
#
#   coproc TUNNEL { tsh proxy db --tunnel "$DB" --port 0 2>&1 }
#   trap 'kill -9 $TUNNEL_PID 2>/dev/null' EXIT
#
#   sleep 0.5
#
#   local line port
#   while read -r line <&p; do
#     if [[ $line =~ (localhost|127\.0\.0\.1):([0-9]+) ]]; then
#       port=${match[2]}
#       break
#     fi
#   done
#
#   export PGHOST=localhost PGPORT=$port PGUSER=$DB_USER PGDATABASE=$DB_NAME
#   pgcli
# }

pg1() {
  set -eu

  DB_ALIAS=$1
  db_port="55432"

  case $DB_ALIAS in
    prd)
      DB=prd-monolith-reader
      DB_NAME=spothero_production
      DB_USER=teleport_reader
      ;;
    *)
      print -u2 "Unknown database – try: tsh db ls"
      return 1
      ;;
  esac

  tsh db login "$DB" --db-user="$DB_USER" --db-name="$DB_NAME"

  # trap 'pkill -P $$' SIGINT SIGTERM

  tsh proxy db --port "$db_port" --tunnel --db-user="$DB_USER" --db-name="$DB_NAME" "$DB" >/dev/null 2>&1 &
  local TSH_PID=$! 
  sleep 2  # give time for teleport proxy to connect.

  export PGHOST=localhost PGPORT=$db_port PGUSER=$DB_USER PGDATABASE=$DB_NAME
  pgcli
  pkill -P "$TSH_PID"  # kill the teleport proxy
}

pg() {
  set -eu

  DB_ALIAS=$1
  db_port="55432"

  case $DB_ALIAS in
    prd)
      DB=prd-monolith-reader
      DB_NAME=spothero_production
      DB_USER=teleport_reader
      ;;
    *)
      print -u2 "Unknown database – try: tsh db ls"
      return 1
      ;;
  esac

  tsh db login "$DB" --db-user="$DB_USER" --db-name="$DB_NAME"

  trap 'pkill -P $$' SIGINT SIGTERM

  nohup tsh proxy db --port "$db_port" --tunnel --db-user="$DB_USER" --db-name="$DB_NAME" "$DB" >/dev/null 2>&1 &
  sleep 2  # give time for teleport proxy to connect.

  export PGHOST=localhost PGPORT=$db_port PGUSER=$DB_USER PGDATABASE=$DB_NAME
  psql "postgres://${DB_USER}@localhost:${db_port}/${DB_NAME}"
  pkill -P $$  # kill the teleport proxy
}

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

which pyenv &> /dev/null
if [ $? -eq 0 ]; then
  eval "$(pyenv init -)"
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# Add pg_config to PATH for Postgres client use
export PATH="$(brew --prefix libpq)/bin:$PATH"

export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

. /opt/homebrew/opt/asdf/libexec/asdf.sh
export TELEPORT_AUTH=onelogin TELEPORT_PROXY=spothero-cloud.teleport.sh

export PATH="$PATH:~/.shoehorn/git-repo/bin"
eval "$(direnv hook zsh)"

export PATH="$PATH:$HOME/.config/emacs/bin"

# Teleport stuff
export GOPROXY= # intentially unset GOPROXY for local builds
export TELEPORT_AUTH=onelogin TELEPORT_PROXY=spothero-cloud.teleport.sh
alias dj='python manage.py'
# helm-proxy allows one to deploy dune sandboxes teleport
function helm-proxy {
  tsh login
  tsh app login chartmuseum

  helm repo remove chartmuseum
  helm repo add chartmuseum https://chartmuseum.spothero-cloud.teleport.sh/ \
    --cert-file $(tsh app config --format cert chartmuseum) \
    --key-file $(tsh app config --format key chartmuseum)
}
alias nexus-proxy='if tsh status >/dev/null 2>&1 && curl -m 5 -s localhost:9914 >/dev/null; then echo "Nexus proxy is already authenticated and working"; else kill $(lsof -i :9914 | tail -n1 | awk "{print \$2}") >/dev/null 2>&1; tsh login; tsh app login nexus ; tsh proxy app  --port=9914 nexus & sleep 1; fi'
alias java-17="export JAVA_HOME=`/usr/libexec/java_home -v 17`; java -version"
alias java-12="export JAVA_HOME=`/usr/libexec/java_home -v 12`; java -version"
source $HOME/.spothero/cloud-ob/init.sh # load bearing comment FORTMARLENE --spothero/cloud-onboarding

export AWS_PROFILE=hub
function sbx {
  # Example usage:
  #   # With SFDC and Celery disabled
  #   sbx chris-htools-1234 pr-9876
  #
  #   # With SFDC and Celery enabled
  #   sbx chris-htools-1234 pr-9876 true true

  NAME=$1
  IMAGE_TAG=$2
  SALESFORCE_ENABLED=${3:-false}
  CELERY_ENABLED=${4:-false}
  if [ "$CELERY_ENABLED" = "false" ]; then
    CELERY_ALWAYS_EAGER=true
  else
    CELERY_ALWAYS_EAGER=false
  fi
  tawsexec --app hub helm-sops upgrade --install --kube-context sbx --namespace consumer $NAME charts/spothero-django --set image.tag=$IMAGE_TAG --set django.salesforce.enabled=$SALESFORCE_ENABLED --set celery.enabled=$CELERY_ENABLED --set django.celery.alwaysEager=$CELERY_ALWAYS_EAGER -f charts/spothero-django/secrets-sbx.yaml
}

# Attempt to fix brief clears of the terminal screen in neovim
export NVIM_TUI_ENABLE_TRUE_COLOR=1

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
bindkey '^[[200~' bracketed-paste
bindkey '^[[201~' bracketed-paste
