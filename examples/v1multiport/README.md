**Multi Port Example**

# Create Resources
```bash
kubectl apply -f intentions.yaml && \
kubectl apply -f backend.yaml && \
kubectl apply -f frontend.yaml && \
kubectl apply -f s3.yaml && \
kubectl apply -f gateway.yaml && \
kubectl apply -f gw-intentions.yaml && \
kubectl apply -f httproute.yaml
```

Browse to http://127.0.0.1:8888 where the API GW is mapped to the frontend LB service.


# Shortcuts

## Create
```bash
find ./ -maxdepth 1 -iname "*.yaml" -exec kubectl apply -f {} \;
```
## Destroy
```bash
find ./ -maxdepth 1 -iname "*.yaml" -exec kubectl delete -f {} \;
```
