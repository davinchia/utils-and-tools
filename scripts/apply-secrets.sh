#!/usr/bin/env bash

# This script retrieves and applies all secrets at a given path
# to a given namespace.
#
# Secrets are saved to a tmp directory. The kubectl apply is then performed 
# on the entire directory. This is currently the easiest way to apply configuration.
# The tmp directory is deleted when the script finishes.
#
# Note: Recursive retrieval is not supported. i.e. All vault keys located
# at $secret_path need to be secrets. 

export tmp_file=/tmp/secrets
export secret_path=secret/yamls/pixel/gazette
export namespace=default

if [ -d "$tmp_file" ]; then
  echo "Clearing temp secrets directory at $tmp_file"
  rm -r $tmp_file
fi

echo "Creating temp secrets directory.."
mkdir -p $tmp_file

echo "Downloading secrets.."
keys=$(vault list $secret_path | grep -v Keys | grep -v '\-\-\-')
for key in $keys; do
    echo $key
    vault read --format=json $secret_path/$key | jq .data > $tmp_file/$key.json
done 


echo "Applying secrets.."
kubectl apply -f $tmp_file -n $namespace

echo "Done writing secrets"

echo "Removing temp secrets directory.."
rm -r $tmp_file
