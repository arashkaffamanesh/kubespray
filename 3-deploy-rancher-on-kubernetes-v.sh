#!/bin/bash
export KUBECONFIG=kube.config
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
helm init --service-account tiller
kubectl rollout status deployment tiller-deploy -n kube-system
# sleep 60
#helm install stable/cert-manager --name cert-manager --namespace kube-system --version v0.5.2
#sleep 60
#kubectl -n kube-system rollout status deploy/cert-manager
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create ns cattle-system
kubectl -n cattle-system create secret generic tls-ca --from-file=./ca/rancher/cacerts.pem
kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=./ca/rancher/cert.pem --key=./ca/rancher/key.pem
kubectl get secrets -n cattle-system
# using own slef signed private CA certificate
kubectl taint node node1 node-role.kubernetes.io/master=effect:NoSchedule
kubectl label node node2 node-role.kubernetes.io/node=
kubectl label node node3 node-role.kubernetes.io/node=
kubectl label node node4 node-role.kubernetes.io/node=
helm install --name rancher rancher-stable/rancher --namespace cattle-system --set hostname=node2  --set ingress.tls.source=secret --set privateCA=true
# helm install --name rancher rancher-stable/rancher --namespace cattle-system --set hostname=node2 --set tls=external
# with jetstack/cert-manager
# kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
# kubectl create namespace cert-manager
# kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm install   --name cert-manager   --namespace cert-manager   --version v0.9.1   jetstack/cert-manager
# kubectl get pods --namespace cert-manager
# with rancher self singned (needs Let's encrypt)
# helm install --name rancher rancher-stable/rancher --namespace cattle-system --set hostname=node2
# with let's encrpyt
# helm install rancher-stable/rancher --name rancher --namespace cattle-system --set hostname=node2 --set ingress.tls.source=letsEncrypt --set letsEncrypt.email=me@example.org
echo "############################################################################"
echo "This should take about 2 minutes, please wait ... "
echo "in the meanwhile open a new shell, change to the install dir and run:"
echo "export KUBECONFIG=credentials/k3s.yaml"
echo "kubectl get all -A"
echo "to see the status of the deployment"
echo "Your browser should open in about 2 minutes and point to:"
echo "https://node2"
echo "############################################################################"
# sleep 300
kubectl -n cattle-system rollout status deploy/rancher
# to be able to access rancher for HA via load balancing on all nodes (to do HA proxy)
kubectl delete ing -n cattle-system rancher
kubectl -f ingress-rancher.yaml -n cattle-system
kubectl get nodes
kubectl get ing -A
# sleep 5
echo ""
# rancher=`./kubectl get pods -n cattle-system | grep rancher |awk 'NR==1{print $1}'`
# open https:/127.0.0.1:4443
echo "############################################################################"
echo "Hope you have fun with k3s on multipass"
echo "If you have any questions and would like to join us on Slack, here you go:"
echo "https://kubernauts-slack-join.herokuapp.com/"
# kubectl port-forward -n cattle-system $rancher 4443:443
open https://node2
# traefik dashboard
# open https://node3
