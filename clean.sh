#!/bin/bash
limactl stop k8s1 && limactl delete k8s1 && \
limactl stop k8s2 && limactl delete k8s2 && \
limactl stop k8s3 && limactl delete k8s3 && \
limactl stop k8s4 && limactl delete k8s4
