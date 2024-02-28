#!/bin/bash
limactl stop k3s1 && limactl delete k3s1 && \
limactl stop k3s2 && limactl delete k3s2 && \
limactl stop k3s3 && limactl delete k3s3 && \
limactl stop k3s4 && limactl delete k3s4
