# Guide to Haproxy

## Commands

```sh
systemctl start haproxy
```

## Config

To get started balancing traffic between our three HTTP listeners, we need to set some options within HAProxy:

* frontend - where HAProxy listens to connections
* backend - Where HAPoxy sends incoming connections
* stats - Optionally, setup HAProxy web tool for monitoring the load balancer and its nodes

### Sample config

Taken from https://serversforhackers.com/c/load-balancing-with-haproxy

```HAProxy
global
    user haproxy
    group haproxy

defaults
    mode http
    log global
    retries 2
    timeout connect 3000ms
    timeout server 5000ms
    timeout client 5000ms

frontend localnodes
    bind *:80
    mode http
    default_backend nodes

backend nodes
    mode http
    balance roundrobin
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server web01 127.0.0.1:9000 check
    server web02 127.0.0.1:9001 check
    server web03 127.0.0.1:9002 check
```

### Adapted config

Adapted from https://medium.com/faun/configuring-ha-kubernetes-cluster-on-bare-metal-servers-with-kubeadm-1-2-1e79f0f7857b

```HAProxy
global
    user haproxy
    group haproxy

defaults
    mode http
    log global
    retries 2
    timeout connect 3000ms
    timeout server 5000ms
    timeout client 5000ms

frontend kubernetes
    mode tcp
    default_backend k8s-masters

    # Load balancer's IP
    bind 134.209.189.11:6443

backend k8s-masters
    mode tcp
    balance roundrobin
    option tcp-check

    # Masters' IPs
    server k8s-master-1 134.209.189.83:6443 check fall 3 rise 2
    server k8s-master-2 134.209.189.16:6443 check fall 3 rise 2
```
