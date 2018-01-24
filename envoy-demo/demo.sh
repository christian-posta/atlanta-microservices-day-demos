#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

desc "Run httpbin"
run "docker run -d --name httpbin citizenstig/httpbin"


desc "Make sure we can curl httpbin"
run "docker run -it --rm --link httpbin tutum/curl curl -X GET http://httpbin:8000/headers"

desc "Take a look at envoy"
run "docker run -it --rm envoyproxy/envoy envoy --help"


desc "Let's run the envoy proxy!"
run "docker run -it --rm envoyproxy/envoy envoy"

desc "damn! no config file"
read -s 

desc "let's take a look at a config"
run "cat conf/simple.json"

desc "Let's run envoy with this config file"
run "docker run -d --name proxy --link httpbin -v $(pwd)/conf/simple.json:/etc/simple.json envoyproxy/envoy envoy -c /etc/simple.json"

desc "Did it come up okay?"
run "docker logs proxy"

desc "Let's curl the proxy"
run "docker run -it --rm --link proxy tutum/curl curl  -X GET http://proxy:15001/headers"

desc "Let's get envoy stats"
run "docker run -it --rm --link proxy tutum/curl curl  -X GET http://proxy:15000/stats" 

desc "Let's get envoy retry stats"
run "docker run -it --rm --link proxy tutum/curl curl  -X GET http://proxy:15000/stats | grep retry"

desc "Let's force errors"
run "docker run -it --rm --link proxy tutum/curl curl  -X GET http://proxy:15001/status/503"

desc "Let's get envoy retry stats"
run "docker run -it --rm --link proxy tutum/curl curl  -X GET http://proxy:15000/stats | grep retry"

desc "clean up"
docker rm -f httpbin proxy
