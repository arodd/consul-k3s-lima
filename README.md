**Linux Example**

```bash
limactl start --name=k8s1 --cpus=8 --memory=4 --vm-type=vz --network=vzNAT template://k3s
```

**Mac**

```bash
brew install lima  
```

**First Cluster Mac**

```bash
#Start first VM K3s cluster
limactl start --name=k8s1 --cpus=8 --memory=4 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=vzNAT template://k3s
#Set Kubeconfig to the first cluster
export KUBECONFIG="/Users/austin/.lima/k8s1/copied-from-guest/kubeconfig.yaml"

#Create Consul Namespace
kubectl create namespace consul

#Create Enterprise License Secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul


#This should return your license key
kubectl get secret -n consul consul-ent-license -o yaml | yq .data.key | base64 -d

# Apply Persistent Volume Claims
kubectl apply -f pvc.yaml

#Install Consul to first cluster
consul-k8s install -config-file=values.yaml

#Expose api to the consul cli
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false
```

**Second Cluster Mac**

```bash
#Start Second K3s VM
limactl start --name=k8s2 --cpus=8 --memory=4 --vm-type=vz --rosetta --mount-type=virtiofs --mount-writable --network=vzNAT template://k3s

#Change Second Cluster API Port and set Kube config
sed -e 's/6443/7443/g' $HOME/.lima/k8s2/copied-from-guest/kubeconfig.yaml > $HOME/.lima/k8s2/copied-from-guest/kubeconfig-fwd.yaml
export KUBECONFIG="$HOME/.lima/k8s2/copied-from-guest/kubeconfig-fwd.yaml"

#Forward Second Cluster API to unique port(run in separate shell)
ssh -F $HOME/.lima/k8s2/ssh.config lima-k8s2 -L 7443:127.0.0.1:6443

#Create Consul Namespace
kubectl create namespace consul

#Create Enterprise License Secret
secret=$(cat ~/consul.hclic)
kubectl create secret generic consul-ent-license --from-literal="key=${secret}" -n consul


#This should return your license key
kubectl get secret -n consul consul-ent-license -o yaml | yq .data.key | base64 -d

# Apply Persistent Volume Claims
kubectl apply -f pvc.yaml

#Install Consul to second cluster
consul-k8s install -config-file=values2.yaml

#Expose api to the consul cli
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central2-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
export CONSUL_HTTP_ADDR=https://127.0.0.1:9501
export CONSUL_HTTP_SSL_VERIFY=false
consul operator raft list-peers
```

**Cluster Peering**

```bash
#Set Kubeconfig to the first cluster
export KUBECONFIG="/Users/austin/.lima/k8s1/copied-from-guest/kubeconfig.yaml"

#Expose api to the consul cli
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central1-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
echo $CONSUL_HTTP_TOKEN
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Generate Cluster Peering Token
export PEERING_TOKEN=$(consul peering generate-token -name us-central2-default)
echo $PEERING_TOKEN

#Switch to second cluster
export KUBECONFIG="$HOME/.lima/k8s2/copied-from-guest/kubeconfig-fwd.yaml"
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret us-central2-bootstrap-acl-token -o yaml | yq -r .data.token | base64 -d)
export CONSUL_HTTP_ADDR=https://127.0.0.1:9501
export CONSUL_HTTP_SSL_VERIFY=false

#Peering over Mesh Gateways
kubectl apply -f meshgw.yaml

#Establish peering connection
consul peering establish -name us-central1-default -peering-token $PEERING_TOKEN
```

**Cleanup**

```bash
limactl stop k8s1  
limactl delete k8s1

limactl stop k8s2
limactl delete k8s2
```
