# isucon11q

https://docs.google.com/document/d/12ODCG0R_CePIuXM5x4UByqYhK6Cftx2QtfQRb3_fJvk/edit#

```
git clone git@github.com:atetubou/isucon11q.git
```

## negainoidoの非ゼロの得点推移 (JST)

|time      |score   |
|----------|-------:|
| 10:10:13 |   2107 |
| 10:28:36 |   1653 |
| 10:32:33 |   1342 |
| 10:38:56 |   1523 |
| 10:46:38 |   1271 |
| 10:57:42 |   1266 |
| 11:06:38 |  12036 |
| 11:11:50 |  11890 |
| 11:16:18 |  11174 |
| 11:28:34 |  12498 |
| 11:34:27 |  12672 |
| 11:43:12 |  11824 |
| 11:52:10 |  12452 |
| 11:58:06 |  14866 |
| 12:03:31 |  14206 |
| 12:05:07 |  15086 |
| 12:14:04 |  18082 |
| 12:18:34 |  20230 |
| 12:22:44 |  21066 |
| 12:34:56 |  25814 |
| 12:43:00 |    999 |
| 13:06:48 |  31968 |
| 13:16:03 |  32950 |
| 13:23:44 |  34722 |
| 13:28:23 |  42900 |
| 13:41:04 |  22103 |
| 13:59:37 |  42752 |
| 14:02:09 |  25575 |
| 14:05:45 |  44068 |
| 14:17:35 |  45794 |
| 14:34:03 |  46568 |
| 14:40:05 |  46333 |
| 14:45:10 |  45474 |
| 15:22:24 |  44945 |
| 15:27:06 |  46008 |
| 15:36:43 |  44012 |
| 15:42:25 |   1000 |
| 15:46:45 |  41775 |
| 15:49:09 |  46917 |
| 16:01:33 |  48164 |
| 16:07:29 |  48392 |
| 16:11:37 |  46750 |
| 16:16:52 |  48964 |
| 16:27:03 |  78977 |
| 16:32:51 |  45776 |
| 16:36:35 |  79693 |
| 16:49:34 |  82019 |
| 16:54:24 |  49677 |
| 16:59:03 | 104355 |
| 17:02:57 | 122413 |
| 17:06:03 | 136560 |
| 17:09:10 | 152471 |
| 18:11:07 | 137818 |
| 18:13:27 | 173087 |
| 18:16:12 | 151572 |
| 18:18:42 | 180943 |
| 18:27:06 | 194635 |
| 18:30:15 | 172965 |
| 18:33:54 | 198651 |

# Memo
## systemdについて
https://qiita.com/tukiyo3/items/092fc32318bd3d1a0846

## サービスの確認
```
sudo systemctl list-units --type=service
```

## サービスの場所
```
/etc/systemd/system/*.service
```

## ログ表示
```
sudo journalctl
sudo journalctl -u isuda.perl
```

## リスンしているプロセスの確認
80番ポートでリスンしているプロセスの確認
```
sudo lsof -P -i :80
```

## MySQLについて
schemaを得る

```
mysqldump dbname --no-data | less
```
or
```
./isucon.sh mysql
```



## slow queryの解析
mysqldの設定に以下を追加
```
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 0
```

解析は次のようにやる。
```
mysqldumpslow /var/log/mysql/mysql-slow.log -s t
```


## escape sequence
https://misc.flogisoft.com/bash/tip_colors_and_formatting
```
printf '\033[1m\033[33mBold\033[m'
```


## xpanes
tmuxを各スクリーンで異なるコマンドを簡単につかえる
https://github.com/greymd/tmux-xpanes


## 複数インスタンスのそれぞれのコスト考察
フロントエンドn台 + DB1台とする。
GETの回数g、POSTの回数pとする。

1. SYNC
syncmapに変更があったときには全てのインスタンスにブロードキャストする
   (かつ、DBに書き込む。書き込みコストはロックがかからない状況では無視できるはず。）
2. DB
DBだけがデータを持つ
3. HASH
分散ハッシュ (Redis/Memcached)

(a) DBへのinsertのコストは無視したとき
内部ネットワークの通信コスト
SYNC: (n-1)p
DB  : p + g
HASH: (1 - 1/n)(p + g)
（キャッシュヒットする確率 = (1 - 1/n)だから。）
SYNC <= HASH iff p/g <= (1 - 1/n) / (n - 2 + 1/n) = (n - 1) / (n^2 - 2n + 1) = 1 / (n - 1)
n = 2のとき p/g <= 1
n = 3のとき p/g <= 0.5
n = 4のとき p/g <= 0.33
n = 5のとき p/g <= 0.25

GETの方がPOSTに比べて4倍多いとき、SYNCを採用するのが最も良い。


## isucon7qの画像に関する考察
設計A: 画像サーバーを一箇所に作る。
設計B: 画像がPOSTされたサーバーに保存し、画像の名前にサーバーの名前を埋め込んでおいて、nginxで適切なサーバーに振り分ける。
設計C: 画像がPOSTされたときにブロードキャストする。
設計D(?): 設計Bにおいて、画像URLをいじってGETが適切なサーバーに向くようにする。この設計は完全にコストが0になる。

内部で画像を送受信するコストを1として、それぞれの設計のコストを見積もる。
また、GET/POSTリクエストはn台のサーバーにランダムに送られるものとする。
A = 画像サーバー以外にリクエストが来たときのみ、コストが1かかる。
  = (1 - 1/n) (p + g)
B = POSTはコスト0。GETは画像があるサーバー以外にリクエストがあったときのみ、コストが1かかる。
  = (1 - 1/n) g
C = GETはコスト0。POSTは(n-1)個のサーバーにブロードキャストするので、コスト(n-1)がかかる。
  = (n - 1) p

C <= B  iff  p/g <= 1/n


## Concurrencyを上げるための手法
http://golang.rdy.jp/2016/07/27/concurrency/
二つデータを用意しておいてswapして更新をする。


## 各種設定について
nginx.confに

```
worker_rlimit_nofile  65535;
events {
    worker_connections 2048;
}
```

としてconnectionなどを増やすと負荷が高いときにエラーがでなくなる。
また、Too many open filesに対してfile descriptorの数を増やす。

/etc/security/limits.conf
```
* hard nofile 65535
* soft nofile 65535
```

mysqlのmax_connectionも大きくしておくべき

/etc/mysql/mysql.conf.d/mysqld.cnf
```
max_connections        = 1000
```

golangのhttpの設定。APIコールをしているときに特に有効。
```
http.DefaultTransport.(*http.Transport).MaxIdleConnsPerHost = 100
```




# 初動など

## コンテスト前

~/ssh/known_hostsをクリア
gitレポジトリの作成

## 各サーバのエイリアスを追加

```
sudo tee -a /etc/hosts <<EOF
192.168.33.11 app1 app1
192.168.33.12 app2 app2
192.168.33.13 app3 app3
EOF
sudo tee /etc/hostname <<< app1
```


## 各サーバに鍵を配送

```
./ssh/distribute.sh PASSWORD app{1,2,3}
```

## tmuxを複数ウィンドウで開く

```
xpanes -c "ssh {}" app{1,2,3}
```

## サーバにgitを配置して初期化

```
git clone $REPOSITORY_URL
cd isucon11q
./isucon.sh init
git add ./etc ./go init.sh
git commit -a
git push
```

## logger.sh, logger.goを配置

```
./isucon.sh install
```

## public folderも追加する
```
./isucon.sh add isubata.golang.service /home/isucon/isubata/webapp/public ./public
```
引数はそれぞれ関係するサービス名, コピー元, コピー先

## 必要なものをインストール
```
./tools/install.sh
```

## /home/isucon/env.shなどを参照してDB_HOST, DB_USER, DB_PASSWORDを確認して.my.cnfに書き込む。
```
DB=$(sed -n 's/^database=//p' ~/.my.cnf)
```

## データベースのバックアップ及び情報の確認

```
./isucon.sh mysql  # => schema.sqlが作成される
git add schema.sql && git commit -m "add schema.sql" && git push
mysqldump --single-transaction $DB | gzip >/tmp/dump.sql.gz
```

データベースの復元方法:
```
zcat /tmp/dump.sql.gz | pv | mysql
```

## initializeでloggerを開始させる

以下をfunc init() {}などに追加。（詳しくは./tools/logger.goを参照)
```
StartLogger(GetNextLogID())
```

# そのほか

## rpccluster
See https://godoc.org/bitbucket.org/tailed/golang/rpccluster

```
import "bitbucket.org/tailed/golang/rpccluster"

var cluster *rpccluster.Cluster = rpccluster.NewCluster(20000, "app1:20000", "app2:20000", "app3:20000")

func init() {
	rpccluster.Register("InitializeMain", InitializeMain)
}

func getInitialize(c echo.Context) error {

    logid := GetNextLogID()
    cluster.CallAll("InitializeMain", logid)
    return c.String(204, "")
}
func InitializeMain(logid string) {
    StartLogger(logid)
}
```

## /etc/nginx/sites-enabled/nginx.confにloggerアクセスを追加
```
location /adminlog/ {
	alias /home/.../isucon/log/;
	autoindex on;
}
```

## import "text/template"を書き換え
```
import "bitbucket.org/tailed/template"
```


## logviewer
ログを解析してくれる。
デフォルトでは8080でlistenしてログを表示する。
cpu.prof, trace.profなどのファイルがきたときには適切にgo tool pprofやgo tool traceを使ってインタラクティブに表示する。
```
cd ./logviewer
make
sudo make install
```

## deepcopy
Goのコピーはshallowコピーなので、構造体をコピーするときは注意する必要がある。

[deep-copy](https://github.com/globusdigital/deep-copy)
