#!/bin/bash
set -euxo pipefail

#Create Clusters using Memory and CPU settings from templates
#Disabling 3&4 until I finish plumbing

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     seq 1 2 | xargs -P 4 -I {} limactl --tty=false start --name=k3s{} --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s{}.yaml;;
    Darwin*)    seq 1 2 | xargs -P 4 -I {} limactl --tty=false start --name=k3s{} --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s{}.yaml;;
    *)          echo "Unknown Machine Type UNKNOWN:${unameOut}" && exit 1
esac

#Set context to Cluster1
export KUBECONFIG="$HOME/.lima/k3s1/copied-from-guest/kubeconfig.yaml"


#Installation Pre-reqs
secret=$(cat ~/consul.hclic)
kubectl create namespace consul
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul
kubectl apply -f pvc.yaml

#Set context to Cluster2
export KUBECONFIG="$HOME/.lima/k3s2/copied-from-guest/kubeconfig.yaml"
kubectl create namespace consul
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul
kubectl apply -f pvc.yaml


#Install Consul on Clusters
seq 1 2 | xargs -P 4 -I {} sh -c "KUBECONFIG=$HOME/.lima/k3s{}/copied-from-guest/kubeconfig.yaml consul-k8s install -auto-approve -config-file=values{}.yaml"

#Set context to Cluster1
export KUBECONFIG="$HOME/.lima/k3s1/copied-from-guest/kubeconfig.yaml"
#Set Cluster1 Environment
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo "Cluster 1 Master Token: $CONSUL_HTTP_TOKEN"
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Create Peering Token
export PEERING_TOKEN=$(consul peering generate-token -name us-central2-default)
echo $PEERING_TOKEN

#Change context to Cluster2
export KUBECONFIG="$HOME/.lima/k3s2/copied-from-guest/kubeconfig.yaml"

#Set Cluster2 Environment
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central2-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo "Cluster 2 Master Token: $CONSUL_HTTP_TOKEN"
export CONSUL_HTTP_ADDR=https://127.0.0.1:9501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateway
kubectl apply -f meshgw.yaml

#Establish Peering Connection
consul peering establish -name us-central1-default -peering-token $PEERING_TOKEN
