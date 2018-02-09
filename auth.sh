
#!/bin/bash
#
# See usage().

[[ -n $DEBUG ]] && set -x

set -eou pipefail
IFS=$'\n\t'

# We do this so the called script name variable is avilable in utility functions
# below, in case of name change, brew alias, etc.
SCRIPT=`basename ${BASH_SOURCE[0]}`

usage() {
  cat <<EOF
${SCRIPT}(1)
NAME
    ${SCRIPT} - Generates the necessary authentication mechanisms for trigger-gcp-cloudbuild.
REQUIRES
    gcloud(1)
SYNOPSIS
    ${SCRIPT} [OPTIONS]
DESCRIPTION
    ${SCRIPT} is a quick shell script to generate authentication mechanisms. ${SCRIPT} prompts for:
      - <SA-NAME> (defaults to "trigger-gcb".)
    ENTER to use the default.
OPTIONS
    -h, --help
        Show this help message
SEE ALSO
    gcloud(1)
EOF
}

sa_create() {
  gcloud iam service-accounts create $SA_NAME
}

roles() {
  SA_EMAIL=$(gcloud iam service-accounts list --filter="name:$SA_NAME" --format='value(email)')
  PROJECT=$(gcloud info --format='value(config.project)')
  gcloud projects add-iam-policy-binding $PROJECT --role roles/cloudbuild.builds.editor --member serviceAccount:$SA_EMAIL --role roles/storage.admin
}

json_key() {
  gcloud iam service-accounts keys create $SA_NAME.json --iam-account $SA_EMAIL
}

# Transform long options to short ones. Sick trick.
# http://stackoverflow.com/a/30026641/4096495
for arg in "$@"; do
  shift
  case "$arg" in
    "--help")       set -- "$@" "-h" ;;
    *)              set -- "$@" "$arg"
  esac
done

while getopts :h OPT; do
  case $OPT in
    h ) HELP=true;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    : ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
  esac
done
shift $((OPTIND-1))

# Usage, list, and exec should not happen simultaneously, so elif.
if [[ ${HELP:-} == 'true' ]]; then
  usage; exit 0
else
  echo "Service Account name? (default ${SA_NAME:-trigger-gcb}):"; read SA_NAME;
  sa_create
  roles
  json_key
fi
