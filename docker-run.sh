#!/usr/bin/env bash
make docker

docker run -d --name injector -p 8443:443 --mount type=bind,src=${GOPATH}/src/github.com/knd2122/kube-sidecar-injector/sample,dst=/etc/mutator khoaitaybeo86/kube-sidecar-injector:latest -logtostderr

docker logs -f $(docker ps -f name=injector -q)
