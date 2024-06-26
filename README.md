# ゾンビプロセスの検証

## 再現方法

```
./parent.sh &
ps j
```

## ゾンビプロセスが生まれるまで

parent.sh -> child.sh -> sleep.sh の順に起動される。
Docker などのコンテナ環境などで、PID 1 が init プロセスではない場合に、wait するプロセスがいなくなってしまう。
親プロセスから KILL すると、子プロセスは孤児プロセスとなり PID 1 プロセスの子プロセスとなってしまう、しかし上記理由から wait しないのでゾンビプロセスとして残ってしまう。

## 解決手段

上記を回避するためには孫、子、親の順に kill していきたい。(そもそも、お行儀のよいプログラムならば、SIGINT あるいは SIGTERM シグナルを先に送って、ダメそうならこの方法にする方が良い)
子プロセスが何かしている間は余計な処理をしてほしくないがために、子から見た親プロセスに SIGSTOP シグナルを送ってしまうと、その親プロセスは wait しなくなってしまう。
STOP したまま KILL してしまうと、子プロセスは孤児プロセスになってしまう。SIGTERM -> SIGCONT で起こしても、wait されずに親プロセスは死ぬので、子プロセスは孤児プロセスとなる。
そのため、子プロセスを KILL する際は、STOP しておいてもよいが、KILL 後は、親プロセスに SIGCONT シグナルを送り、wait を再開させたうえで、ゾンビプロセスとなっている子プロセスを回収してもらう必要がある。
子プロセスが KILL された後、プロセステーブルから完全に削除されるまで多少のラグがあるので、kill -0 で存在チェックして、確実に削除されてから先の処理に進むのが良い。
子プロセスを復活されるような親プロセスがある場合、あるいは非同期で子プロセスを立ち上げている親プロセスがいる場合、子プロセスを KILL しきれないのでこの方法は使えない。

Docker コンテナでは、Tini などの擬似 init プロセスを立ち上げ、ゾンビプロセスの刈り取りを行うことができるが、AWS Lambda などの一部サーバーレス環境では動作させることはできないようなので、その場合は上記の方法で KILL するか、アプリケーション側が INT、TERM シグナルに対応するのが良さそう。

### 参考 URL

- https://qiita.com/grainrigi/items/3f13b949310b669d08bb
- https://github.com/krallin/tini/issues/218
