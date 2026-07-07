#!/usr/bin/env bash
# install-k3s.sh

curl -sfL https://get.k3s.io | sh -s - server --disable traefik --disable servicelb --write-kubeconfig-mode=644
