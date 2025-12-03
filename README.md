# moneyforward-suica-auto-update
MoneyForwardのモバイルSuicaの項目を更新

## 前提
MoneyForwardでモバイルSuicaは自動更新されないため、手動で更新する

## 動作環境
ローカルのmacからcron等で実行する  
ログイン処理は行わないため、あらかじめブラウザでMoneyForwardにログインしておく

```crontab
30 7 * * * /usr/bin/osascript /path/to/repository/src/mf_suica_update.scpt >> /path/to/repository/log/mf_suica_update.log 2>&1
```

## 手動実行
```
make run
```
