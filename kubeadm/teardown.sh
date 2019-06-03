#!/bin/bash
rm ~/.kube/config
hcloud server delete master
hcloud server delete node1
hcloud server delete node2
