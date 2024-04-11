#!/bin/bash
set -Ceu

# 子プロセスを起動する
./child.sh &

# wait が止まる
kill -STOP $$
