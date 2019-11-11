#!/bin/bash
multipass delete node1 node2 node3 node4 node5 node6 --purge
rm hosts get_helm.sh etchosts etchosts.unix
echo "Please cleanup the host entries in your /etc/hosts manually"
