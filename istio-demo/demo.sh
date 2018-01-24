#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

# grafana: http://localhost:3000
# kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 


# jaeger: http://localhost:16686
# kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.me}') 16686:16686 

SOURCE_DIR=$PWD

desc "Let's take a look at our httpbin service"
run "cat httpbin-v1.yaml"
clear

desc "Let's inject the istio proxy"
run "istioctl kube-inject --tag latest --hub ceposta -f httpbin-v1.yaml"
clear

desc "Let's create the httpbin service"
run "kubectl create -f <(istioctl kube-inject --tag latest --hub ceposta -f httpbin-v1.yaml)"
run "kubectl get pods -w"

desc "Can we query the httpbin service?"
run "kubectl run -i --rm --restart=Never dummy --image=tutum/curl:alpine --command -- curl -s 'http://httpbin:8080/headers'"




tmux split-window -v -d -c $SOURCE_DIR
tmux select-pane -t 1
tmux split-window -h -d -c $SOURCE_DIR
tmux select-pane -t 0

clear

HTTPBIN_V1=$(kubectl get pod | grep httpbin-v1 | awk '{ print $1}')
tmux send-keys -t 1 "kubectl logs -f $HTTPBIN_V1 -c httpbin" C-m
#tmux send-keys -t 1 "kubectl logs -f --since=1s $HTTPBIN_V1 -c httpbin" C-m

desc "Start up our benchmarking test"
run "kubectl create -f <(istioctl kube-inject --tag latest --hub ceposta -f fortio-deploy.yaml --debug)"
run "kubectl get pods -w"

FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')

desc "query our httpbin service"
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 1 -n 5 http://httpbin:8080/get"


clear
tmux send-keys -t 1 C-c
tmux send-keys -t 1 C-l
tmux send-keys -t 1 "kubectl logs -f --since=1s $HTTPBIN_V1 -c httpbin" C-m

desc "Let's create a version 2 of our httpbin service"
read -s 
run "kubectl create -f <(istioctl kube-inject --tag latest --hub ceposta -f httpbin-v2.yaml)"

run "kubectl get pods -w"


HTTPBIN_V2=$(kubectl get pod | grep httpbin-v2 | awk '{ print $1}')
tmux send-keys -t 2 "kubectl logs -f $HTTPBIN_V2 -c httpbin" C-m
#tmux send-keys -t 2 "kubectl logs -f --since=1s $HTTPBIN_V2 -c httpbin" C-m


desc "Show load balancing across pods/versions"
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -keepalive=false -c 1 -t 5s http://httpbin:8080/get"

clear
tmux send-keys -t 1 C-c
tmux send-keys -t 1 C-l
tmux send-keys -t 1 "kubectl logs -f --since=1s $HTTPBIN_V1 -c httpbin" C-m

tmux send-keys -t 2 C-c
tmux send-keys -t 2 C-l
tmux send-keys -t 2 "kubectl logs -f --since=1s $HTTPBIN_V2 -c httpbin" C-m

desc "Let's see an istio route rule"
run "cat routerules/all-httpbin-v1.yaml"

desc "Let's apply our route rule"
run "istioctl create -f routerules/all-httpbin-v1.yaml"

desc "All load should go to only v1"
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -keepalive=false -c 1 -t 5s http://httpbin:8080/get"

clear

tmux send-keys -t 1 C-c
tmux send-keys -t 1 C-l
tmux send-keys -t 1 "kubectl logs -f --since=1s $HTTPBIN_V1 -c httpbin" C-m

desc "Let's say we want to dark launch the v2 version"
read -s
desc "Only requests with the 'x-dark-launch' header should be allowed to v2"
run "cat routerules/dark-launch-v2.yaml"

desc "apply the new rule"
run "istioctl create -f routerules/dark-launch-v2.yaml"


desc "query our httpbin service"
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 1 -n 5 http://httpbin:8080/get"

clear

desc "Now try passing in the dark launch header"
run "kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 1 -n 5 -H 'x-dark-launch: v2' http://httpbin:8080/get"


# Circuit breaking

