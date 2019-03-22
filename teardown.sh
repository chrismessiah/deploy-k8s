#!/bin/bash
rm ~/.kube/config

doctl compute droplet delete -f master
doctl compute droplet delete -f node1
