**Multi Port Example**

```bash
kubectl apply -f intentions.yaml && \
kubectl apply -f backend.yaml && \
kubectl apply -f frontend.yaml
```

Browse to http://127.0.0.1:8000 where the frontend LB is mapped.
