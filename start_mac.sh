#!/bin/bash
#Create Cluster1
limactl --tty=false start --name=k8s1 --cpus=6 --memory=3 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s.yaml
#Create Cluster2
limactl --tty=false start --name=k8s2 --cpus=6 --memory=3 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s2.yaml
#Create Cluster3
#limactl --tty=false start --name=k8s3 --cpus=6 --memory=1 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s3.yaml
#Create Cluster4
#limactl --tty=false start --name=k8s4 --cpus=6 --memory=1 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s4.yaml


#Set context to Cluster1
export KUBECONFIG="$HOME/.lima/k8s1/copied-from-guest/kubeconfig.yaml"

#Create Consul Namespace
kubectl create namespace consul

#Store Enterprise License key in installation secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul

#Create local pvc
kubectl apply -f pvc.yaml

#Install Consul on Cluster1
consul-k8s install -auto-approve -config-file=values.yaml

#Set Cluster1 Environment
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Create Peering Token
export PEERING_TOKEN=$(consul peering generate-token -name us-central2-default)
echo $PEERING_TOKEN

#Change context to Cluster2
export KUBECONFIG="$HOME/.lima/k8s2/copied-from-guest/kubeconfig.yaml"

#Create Consul Namespace
kubectl create namespace consul

#Create Enterprise license installation secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul

#Create local pvc
kubectl apply -f pvc.yaml

#Install Consul on Cluster2
consul-k8s install -auto-approve -config-file=values2.yaml

#Set Cluster2 Environment
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central2-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:9501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateway
kubectl apply -f meshgw.yaml

#Establish Peering Connection
consul peering establish -name us-central1-default -peering-token $PEERING_TOKEN
