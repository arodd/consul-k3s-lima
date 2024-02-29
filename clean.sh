#!/bin/bash
seq 1 4 | xargs -P 4 -I {} limactl --tty=false stop k3s{}
seq 1 4 | xargs -P 4 -I {} limactl --tty=false delete k3s{}
