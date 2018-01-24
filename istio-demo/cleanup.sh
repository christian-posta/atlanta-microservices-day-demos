#!/bin/bash


#tmux kill-pane -t 2 
#tmux kill-pane -t 1 

kubectl delete deploy fortio httpbin-v1 httpbin-v2
kubectl delete svc/httpbin
kubectl delete routerules --all
kubectl delete destinationpolicy --all

