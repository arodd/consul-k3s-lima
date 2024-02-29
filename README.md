# arm64 Mac deployment
```bash
brew install lima  
```

## Automated Bootstraping

**Deploy 2 K3s clusters using lima vm's**
```bash
./start_mac.sh
```

**Run Commands in us-central1**
```bash
source cluster1.env
kubectl get all -n consul
```

**Run Commands in us-central2**
```bash
source cluster2.env
kubectl get all -n consul
```

**Guest SSH Access**
```bash
ssh -F $HOME/.lima/k3s1/ssh.config lima-k3s1
ssh -F $HOME/.lima/k3s2/ssh.config lima-k3s2
ssh -F $HOME/.lima/k3s3/ssh.config lima-k3s3
ssh -F $HOME/.lima/k3s4/ssh.config lima-k3s4
```

**Cleanup Clusters**
```bash
./clean.sh
```

## Manual Bootstrapping
**First Cluster Mac**

```bash
#Start first VM K3s cluster
limactl start --name=k3s1 --cpus=6 --memory=3 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s1.yaml
#Set Kubeconfig to the first cluster
export KUBECONFIG="$HOME/.lima/k3s1/copied-from-guest/kubeconfig.yaml"

#Create Consul Namespace
kubectl create namespace consul

#Create Enterprise License Secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul


#This should return your license key
kubectl get secret -n consul consul-ent-license -o yaml | yq -r .data.key | base64 -d

# Apply Persistent Volume Claims
kubectl apply -f pvc.yaml

#Install Consul to first cluster
consul-k8s install -config-file=values1.yaml

#Expose api to the consul cli
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false
consul operator raft list-peers

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Generate Cluster Peering Token
export PEERING_TOKEN=$(consul peering generate-token -name us-central2-default)
echo $PEERING_TOKEN
```

**Second Cluster Mac**

```bash
#Start Second K3s VM
limactl start --name=k3s2 --cpus=6 --memory=3 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=lima:user-v2 k3s2.yaml

#Change Second Cluster API Port and set Kube config
export KUBECONFIG="$HOME/.lima/k3s2/copied-from-guest/kubeconfig.yaml"

#Create Consul Namespace
kubectl create namespace consul

#Create Enterprise License Secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul

#This should return your license key
kubectl get secret -n consul consul-ent-license -o yaml | yq -r .data.key | base64 -d

# Apply Persistent Volume Claims
kubectl apply -f pvc.yaml

#Install Consul to second cluster
consul-k8s install -config-file=values2.yaml

#Expose api to the consul cli
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central2-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:9501
export CONSUL_HTTP_SSL_VERIFY=false
consul operator raft list-peers

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Establish peering connection
consul peering establish -name us-central1-default -peering-token $PEERING_TOKEN
```

**Cleanup**

```bash
limactl stop k3s1 && limactl delete k3s1 && \
limactl stop k3s2 && limactl delete k3s2
```
