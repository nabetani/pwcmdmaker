# pwcmdmaker

パスワードを謎のコマンドに憶えてもらうためのスクリプト。

## これは何？

```shell
$ ruby pwcmdmaker.rb create secret-command czqrMVkOGYaZAfUIHX4m himitsu
```

と実行すると、 `/usr/local/bin` に `secret-command` というコマンドができる。

```shell
$ secret-command himitsu
```

と実行すると、`czqrMVkOGYaZAfUIHX4m` がクリップボードにコピーされる。
というもの。


