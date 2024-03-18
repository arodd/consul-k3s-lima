#!/bin/bash
set -euxo pipefail

#Set context to Cluster1
export KUBECONFIG="$HOME/.lima/k3s1/copied-from-guest/kubeconfig.yaml"
#Set Cluster1 Environment
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo "Cluster 1 Master Token: $CONSUL_HTTP_TOKEN"
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Delete old peering connection
consul peering delete -name us-central2-default

sleep 3
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

#Delete old peering connection
consul peering delete -name us-central1-default

sleep 3
#Establish Peering Connection
consul peering establish -name us-central1-default -peering-token $PEERING_TOKEN
