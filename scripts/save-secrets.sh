#!/usr/bin/env bash

# This script writes all secrets in a given namespace to vault
# with the path secret/yamls/$team/$namespace/$secret-name
# 
# Before being saved, the secrets are saved to a temp directory for sanitation.
# Part of this sanitation includes removing the field specifying the 
# namespace the secret resides in. This allows greater namespace customisation
# when transferring secrets to a new cluster.
#
# The temp directory is deleted when the script finishes.

export tmp_file=/tmp/secrets
export secret_path=secret/yamls
export team
export namespace

tflag=false
nflag=false

usage() {
    echo "script usage: $(basename $0) [-t team] [-n namespace]."
}

while getopts ':t:n:' opt; do
    case $opt in
    t)
      team=$OPTARG
      tflag=true
      ;;
    n)
      namespace=$OPTARG
      nflag=true
      ;;
    ?)
      usage
      exit 1
      ;;
    esac
done

if ! $tflag || ! $nflag 
then
    echo "Missing command line flags.."
    usage
    exit 1
fi

if [ -d "$tmp_file" ]; then
    echo "Clearing temp secrets directory at $tmp_file"
    rm -r $tmp_file
fi

echo "Creating temp secrets directory.."
mkdir -p $tmp_file

echo "Downloading secrets.."
kubectl get secrets -n $namespace | awk -F " " '{print $1}' | grep -v NAME \
| xargs -I % sh -c 'kubectl get secret -n $namespace "$1" -o json > "$tmp_file/$1"' -- %

echo "Writing secrets to vault.."
for filename in $tmp_file/*; do
    # default-token is the authentication token kube uses for the default service account,
    # skip it as it is kube cluster specific.
    if [[ ${filename} != *"default-token"* ]];then
    b=$(basename $filename)
    echo $b
    # Make sure to strip potentially confusing metadata from the secret.
    cat $filename | jq 'del(.metadata.annotations, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.selfLink, .metadata.namespace)' \
    | vault write $secret_path/$team/$namespace/$b -
    fi
done
echo "Done writing secrets"
echo "Secrets saved to $secret_path/$team/$namespace"

echo "Removing temp secrets directory.."
rm -r $tmp_file
