#!/bin/sh

kubectl delete pod -n istio-system $(kubectl get pod -n istio-system | grep grafana | awk '{ print $1 }')
kubectl delete pod -n istio-system $(kubectl get pod -n istio-system | grep mixer | awk '{ print $1 }')
kubectl delete pod -n istio-system $(kubectl get pod -n istio-system | grep pilot | awk '{ print $1 }')
kubectl delete pod -n istio-system $(kubectl get pod -n istio-system | grep prometheus | awk '{ print $1 }')
kubectl delete pod -n istio-system $(kubectl get pod -n istio-system | grep jaeger | awk '{ print $1 }')
