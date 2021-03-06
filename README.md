![Kubernetes Logo](https://raw.githubusercontent.com/kubernetes-sigs/kubespray/master/docs/img/kubernetes-logo.png)

Deploy a Production Ready Kubernetes Cluster with Kubespary and Kubeadm
=======================================================================

## Deployment with multipass VMs on your local machine

## TL;DR

This is a clone of Kubespray repo with few scripts to play on multipass VMs on your local machine.

```bash
git clone git@github.com:arashkaffamanesh/kubespray.git
cd kubespray/
pip3 install -r requirements.txt
# cp -rfp inventory/sample inventory/mycluster
# run 6 VMs for HA
./1-deploy-multipass-vms.sh
# deploy 2 masters with 3 etcds on 3 nodes and 3 workers on 3 other nodes
ansible-playbook -i hosts.ini -u ubuntu -b --key-file=~/.ssh/id_rsa.pub cluster.yml
multipass exec node1 -- bash -c "sudo cat /etc/kubernetes/admin.conf" > kube.config
export KUBECONFIG=kube.config
kubectl get nodes
# deploy metal-lb and ghost for testing
./9-metal-lb.sh
# destroy your cluster
./cleanup.sh
```

## Get the token for the dashboard

```bash
kubectl -n kube-system describe secrets `kubectl -n kube-system get secrets | awk '/clusterrole-aggregation-controller/ {print $1}'` | awk '/token:/ {print $2}'
```

k port-forward -n kube-system kubernetes-dashboard-556b9ff8f8-6pwp6 8443:8443

## Kubespray README

If you have questions, check the [documentation](https://kubespray.io) and join us on the [kubernetes slack](https://kubernetes.slack.com), channel **\#kubespray**.
You can get your invite [here](http://slack.k8s.io/)

-   Can be deployed on **AWS, GCE, Azure, OpenStack, vSphere, Packet (bare metal), Oracle Cloud Infrastructure (Experimental), or Baremetal**
-   **Highly available** cluster
-   **Composable** (Choice of the network plugin for instance)
-   Supports most popular **Linux distributions**
-   **Continuous integration tests**

Quick Start
-----------

To deploy the cluster you can use :

### Ansible

#### Usage

    # Install dependencies from ``requirements.txt``
    sudo pip install -r requirements.txt

    # Copy ``inventory/sample`` as ``inventory/mycluster``
    cp -rfp inventory/sample inventory/mycluster

    # Update Ansible inventory file with inventory builder
    declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
    CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

    # Review and change parameters under ``inventory/mycluster/group_vars``
    cat inventory/mycluster/group_vars/all/all.yml
    cat inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml

    # Deploy Kubespray with Ansible Playbook - run the playbook as root
    # The option `--become` is required, as for example writing SSL keys in /etc/,
    # installing packages and interacting with various systemd daemons.
    # Without --become the playbook will fail to run!
    ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml

Note: When Ansible is already installed via system packages on the control machine, other python packages installed via `sudo pip install -r requirements.txt` will go to a different directory tree (e.g. `/usr/local/lib/python2.7/dist-packages` on Ubuntu) from Ansible's (e.g. `/usr/lib/python2.7/dist-packages/ansible` still on Ubuntu).
As a consequence, `ansible-playbook` command will fail with:
```
ERROR! no action detected in task. This often indicates a misspelled module name, or incorrect module path.
```
probably pointing on a task depending on a module present in requirements.txt (i.e. "unseal vault").

One way of solving this would be to uninstall the Ansible package and then, to install it via pip but it is not always possible.
A workaround consists of setting `ANSIBLE_LIBRARY` and `ANSIBLE_MODULE_UTILS` environment variables respectively to the `ansible/modules` and `ansible/module_utils` subdirectories of pip packages installation location, which can be found in the Location field of the output of `pip show [package]` before executing `ansible-playbook`.

### Vagrant

For Vagrant we need to install python dependencies for provisioning tasks.
Check if Python and pip are installed:

    python -V && pip -V

If this returns the version of the software, you're good to go. If not, download and install Python from here <https://www.python.org/downloads/source/>
Install the necessary requirements

    sudo pip install -r requirements.txt
    vagrant up

Documents
---------

-   [Requirements](#requirements)
-   [Kubespray vs ...](docs/comparisons.md)
-   [Getting started](docs/getting-started.md)
-   [Ansible inventory and tags](docs/ansible.md)
-   [Integration with existing ansible repo](docs/integration.md)
-   [Deployment data variables](docs/vars.md)
-   [DNS stack](docs/dns-stack.md)
-   [HA mode](docs/ha-mode.md)
-   [Network plugins](#network-plugins)
-   [Vagrant install](docs/vagrant.md)
-   [CoreOS bootstrap](docs/coreos.md)
-   [Debian Jessie setup](docs/debian.md)
-   [openSUSE setup](docs/opensuse.md)
-   [Downloaded artifacts](docs/downloads.md)
-   [Cloud providers](docs/cloud.md)
-   [OpenStack](docs/openstack.md)
-   [AWS](docs/aws.md)
-   [Azure](docs/azure.md)
-   [vSphere](docs/vsphere.md)
-   [Packet Host](docs/packet.md)
-   [Large deployments](docs/large-deployments.md)
-   [Upgrades basics](docs/upgrades.md)
-   [Roadmap](docs/roadmap.md)

Supported Linux Distributions
-----------------------------

-   **Container Linux by CoreOS**
-   **Debian** Buster, Jessie, Stretch, Wheezy
-   **Ubuntu** 16.04, 18.04
-   **CentOS/RHEL** 7
-   **Fedora** 28
-   **Fedora/CentOS** Atomic
-   **openSUSE** Leap 42.3/Tumbleweed
-   **Oracle Linux** 7

Note: Upstart/SysV init based OS types are not supported.

Supported Components
--------------------

-   Core
    -   [kubernetes](https://github.com/kubernetes/kubernetes) v1.16.2
    -   [etcd](https://github.com/coreos/etcd) v3.3.10
    -   [docker](https://www.docker.com/) v18.06 (see note)
    -   [cri-o](http://cri-o.io/) v1.14.0 (experimental: see [CRI-O Note](docs/cri-o.md). Only on centos based OS)
-   Network Plugin
    -   [cni-plugins](https://github.com/containernetworking/plugins) v0.8.1
    -   [calico](https://github.com/projectcalico/calico) v3.7.3
    -   [canal](https://github.com/projectcalico/canal) (given calico/flannel versions)
    -   [cilium](https://github.com/cilium/cilium) v1.5.5
    -   [contiv](https://github.com/contiv/install) v1.2.1
    -   [flanneld](https://github.com/coreos/flannel) v0.11.0
    -   [kube-router](https://github.com/cloudnativelabs/kube-router) v0.2.5
    -   [multus](https://github.com/intel/multus-cni) v3.2.1
    -   [weave](https://github.com/weaveworks/weave) v2.5.2
-   Application
    -   [cephfs-provisioner](https://github.com/kubernetes-incubator/external-storage) v2.1.0-k8s1.11
    -   [rbd-provisioner](https://github.com/kubernetes-incubator/external-storage) v2.1.1-k8s1.11
    -   [cert-manager](https://github.com/jetstack/cert-manager) v0.11.0
    -   [coredns](https://github.com/coredns/coredns) v1.6.0
    -   [ingress-nginx](https://github.com/kubernetes/ingress-nginx) v0.26.1

Note: The list of validated [docker versions](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.16.md) was updated to 1.13.1, 17.03, 17.06, 17.09, 18.06, 18.09. kubeadm now properly recognizes Docker 18.09.0 and newer, but still treats 18.06 as the default supported version. The kubelet might break on docker's non-standard version numbering (it no longer uses semantic versioning). To ensure auto-updates don't break your cluster look into e.g. yum versionlock plugin or apt pin).

Requirements
------------
-   **Minimum required version of Kubernetes is v1.15**
-   **Ansible v2.7.8 (or newer, but [not 2.8.x](https://github.com/kubernetes-sigs/kubespray/issues/4778)) and python-netaddr is installed on the machine
    that will run Ansible commands**
-   **Jinja 2.9 (or newer) is required to run the Ansible Playbooks**
-   The target servers must have **access to the Internet** in order to pull docker images. Otherwise, additional configuration is required (See [Offline Environment](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/downloads.md#offline-environment))
-   The target servers are configured to allow **IPv4 forwarding**.
-   **Your ssh key must be copied** to all the servers part of your inventory.
-   The **firewalls are not managed**, you'll need to implement your own rules the way you used to.
    in order to avoid any issue during deployment you should disable your firewall.
-   If kubespray is ran from non-root user account, correct privilege escalation method
    should be configured in the target servers. Then the `ansible_become` flag
    or command parameters `--become or -b` should be specified.

Hardware:
These limits are safe guarded by Kubespray. Actual requirements for your workload can differ. For a sizing guide go to the [Building Large Clusters](https://kubernetes.io/docs/setup/cluster-large/#size-of-master-and-master-components) guide.

-   Master
    - Memory: 1500 MB
-   Node
    - Memory: 1024 MB

Network Plugins
---------------

You can choose between 10 network plugins. (default: `calico`, except Vagrant uses `flannel`)

-   [flannel](docs/flannel.md): gre/vxlan (layer 2) networking.

-   [calico](docs/calico.md): bgp (layer 3) networking.

-   [canal](https://github.com/projectcalico/canal): a composition of calico and flannel plugins.

-   [cilium](http://docs.cilium.io/en/latest/): layer 3/4 networking (as well as layer 7 to protect and secure application protocols), supports dynamic insertion of BPF bytecode into the Linux kernel to implement security services, networking and visibility logic.

-   [contiv](docs/contiv.md): supports vlan, vxlan, bgp and Cisco SDN networking. This plugin is able to
    apply firewall policies, segregate containers in multiple network and bridging pods onto physical networks.

-   [weave](docs/weave.md): Weave is a lightweight container overlay network that doesn't require an external K/V database cluster.
    (Please refer to `weave` [troubleshooting documentation](https://www.weave.works/docs/net/latest/troubleshooting/)).

-   [kube-ovn](docs/kube-ovn.md): Kube-OVN integrates the OVN-based Network Virtualization with Kubernetes. It offers an advanced Container Network Fabric for Enterprises.

-   [kube-router](docs/kube-router.md): Kube-router is a L3 CNI for Kubernetes networking aiming to provide operational
    simplicity and high performance: it uses IPVS to provide Kube Services Proxy (if setup to replace kube-proxy),
    iptables for network policies, and BGP for ods L3 networking (with optionally BGP peering with out-of-cluster BGP peers).
    It can also optionally advertise routes to Kubernetes cluster Pods CIDRs, ClusterIPs, ExternalIPs and LoadBalancerIPs.

-   [macvlan](docs/macvlan.md): Macvlan is a Linux network driver. Pods have their own unique Mac and Ip address, connected directly the physical (layer 2) network.

-   [multus](docs/multus.md): Multus is a meta CNI plugin that provides multiple network interface support to pods. For each interface Multus delegates CNI calls to secondary CNI plugins such as Calico, macvlan, etc.

The choice is defined with the variable `kube_network_plugin`. There is also an
option to leverage built-in cloud provider networking instead.
See also [Network checker](docs/netcheck.md).

Community docs and resources
----------------------------

-   [kubernetes.io/docs/setup/production-environment/tools/kubespray/](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)
-   [kubespray, monitoring and logging](https://github.com/gregbkr/kubernetes-kargo-logging-monitoring) by @gregbkr
-   [Deploy Kubernetes w/ Ansible & Terraform](https://rsmitty.github.io/Terraform-Ansible-Kubernetes/) by @rsmitty
-   [Deploy a Kubernetes Cluster with Kubespray (video)](https://www.youtube.com/watch?v=N9q51JgbWu8)

Tools and projects on top of Kubespray
--------------------------------------

-   [Digital Rebar Provision](https://github.com/digitalrebar/provision/blob/v4/doc/integrations/ansible.rst)
-   [Terraform Contrib](https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform)

CI Tests
--------

[![Build graphs](https://gitlab.com/kargo-ci/kubernetes-sigs-kubespray/badges/master/build.svg)](https://gitlab.com/kargo-ci/kubernetes-sigs-kubespray/pipelines)

CI/end-to-end tests sponsored by Google (GCE)
See the [test matrix](docs/test_cases.md) for details.

## Related links

### Kubernetes Tips: HA Cluster With Kubespray

https://medium.com/better-programming/kubernetes-tips-ha-cluster-with-kubespray-69e5bb2fa444

### Setting up a Kubernetes cluster with Kubespray

https://medium.com/@leonardo.bueno/setting-up-a-kubernetes-cluster-with-kubespray-1bf4ce8ccd73

### Kubernetes on baremetal: kubespray-terraform Multimaster-HA , haproxy-API , Traefik and App’s with Horizontal Pod Autoscaling.

https://medium.com/@earielli/kubernetes-on-baremetal-kubespray-terraform-multimaster-ha-haproxy-api-traefik-and-apps-with-ec165133c5ca

### Kubernetes Cluster Deployment using Kubespray

https://medium.com/@raman.pndy/kubernetes-cluster-deployment-using-kubespray-ebc4bec082c1

### High Available Kubernetes Cluster Setup using Kubespray

https://schoolofdevops.github.io/ultimate-kubernetes-bootcamp/cluster_setup_kubespray/

### Nging Ingress Controller Deployment

https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

https://medium.com/swlh/using-nginx-ingress-controllers-on-kubernetes-on-centos-7-99f6df969b45

https://kubernetes.github.io/ingress-nginx/deploy/#using-helm

https://github.com/helm/charts/tree/master/stable/nginx-ingress#configuration

helm install --namespace ingress-nginx --name nginx-ingress stable/nginx-ingress --set controller.kind=DaemonSet


helm install --namespace ingress-nginx --name nginx-ingress stable/nginx-ingress \
             --set rbac.create=true \
             --set defaultBackend=false \
             --set controller.service.externalTrafficPolicy=Local \
             --set controller.scope.enabled=true \
	         --set controller.kind=DaemonSet

