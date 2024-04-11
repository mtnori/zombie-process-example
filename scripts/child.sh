#!/bin/bash
set -Ceu

# 子プロセスを起動する
./sleep.sh &

# wait が止まる
kill -STOP $$
