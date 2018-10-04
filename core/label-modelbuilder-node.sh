#!/usr/bin/env bash
set -e 

# Model-builder requires access to ArborDB, which is currently hosted on AWS RDS. 
# As a short term solution, we whitelist a static ip, assign that to a node, and
# label that node so model-builder is scheduled on the right node.
# In the long term, ArborDB will be moved to GCP.

# Follow https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address,
# to assign static ips to a node.

# This script has been tested with a brand new cluster. 

# This static ip has already been whitelisted on the RDS security group.
# See, https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:search=sg-0e2d40dae7047711e;sort=groupId
static_ip=35.187.127.4

# 1) Pick any node in the cluster. Modelbuilder does not require any special resources e.g. ssd.
# Note: gcloud config needs to be pointed to the right gcp project. See `gcloud config list`.

# Assume the cluster has `ps` in its name. Always pick the first node.
node=$(gcloud compute instances list | grep ps | head -n 1 | cut -d " " -f 1)
echo "Will assign static ip to $node.."

# 2) Delete old ip config.
name=$(gcloud compute instances describe $node --format=json | jq .networkInterfaces[0].accessConfigs[0].name | tr -d '"')
echo "Deleting $name ip config from $node.."
gcloud compute instances delete-access-config $node  --access-config-name "$name"
echo "$name ip config deleted from $node."

# 3) Assign new config with whitelisted ip address. 
# If ip address is already in use, either manually create a new one or free this.
# If a new address is created, it will have to be manually associated with the RDS security group.
# To unassign, go to https://console.cloud.google.com/networking/addresses/list?project=<project-id>.
gcloud compute instances add-access-config $node \
--access-config-name $name --address $static_ip
echo "Static ip assigned to $node."

# 4) Assign label to new node.
kubectl label node $node amazonrds=true

# 5) Delete old pod so pod is scheduled on right node. 
# Note: Make sure to remove any existing labels nodes.
kubectl delete pod -lapp=model-builder
echo "Deleting old pod.."
