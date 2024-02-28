#!/bin/bash
limactl stop k8s1 && limactl delete k8s1 && \
limactl stop k8s2 && limactl delete k8s2
