#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

SOURCE_DIR=$PWD

#tmux kill-pane -t 2 
#tmux kill-pane -t 1 

desc "Let's take a look at our destination policy:"
run "cat destinationpolicies/destination-policy-httpbin.yaml"


desc "Let's create the circuit breaking policy:"
run "istioctl create -f destinationpolicies/destination-policy-httpbin.yaml"

desc "Now if we try to put a lot of concurrent load, we should see it circuit break"
desc "We'll do two concurrent connections"
read -s

FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 2 -n 10 http://httpbin:8080/get"

desc "Envoy does give a little bit of leeway. Let's increase the concurrent connections to 3"
read -s

run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 3 -n 30 http://httpbin:8080/get"

desc "Let's see what the envoy stats look like during a circuit0-breaking event"
read -s

run "kubectl exec -it $FORTIO_POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats' | grep httpbin | grep pending"