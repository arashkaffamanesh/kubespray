#!/bin/bash
# deploy traefik with dashboard
export KUBECONFIG=kube.config
kubectl create ns traefik
kubectl apply -f ./traefik/ -n traefik
kubectl -n traefik rollout status deployment traefik-ingress-controller
#sleep 90
open https://node4
# username / password : admin / admin