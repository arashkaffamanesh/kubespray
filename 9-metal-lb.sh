#!/bin/bash

kubectl apply -f metallb.yaml

cat <<'_EOF_'> bgp.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    peers:
    - my-asn: 64522
      peer-asn: 64512
      peer-address: 192.168.178.1
      peer-port: 179
      router-id: 192.168.178.1
    address-pools:
    - name: my-ip-space
      protocol: bgp
      avoid-buggy-ips: true
      addresses:
      - 192.168.178.192/26
_EOF_

kubectl apply -f bgp.yaml
# kn default
kubectl apply -f ghost-deployment.yaml
kubectl rollout status deployment ghost
kubectl expose deployments ghost --port=2368 --type=LoadBalancer
kubectl apply -f ghost-ingress.yaml

# k get pods -o wide -n default
# find the node where ghost is running (here node5)
# ghost-64d569d869-txcgb   1/1 Running   0 11m   10.233.70.9   node5
# adapt the node below
# multipass exec node5 -- bash -c "curl 192.168.178.192:2368"

# kubectl create ns ingress-nginx
# kn ingress-nginx
# helm install stable/nginx-ingress --name my-nginx --set rbac.create=true