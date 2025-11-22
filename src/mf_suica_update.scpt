-- mf_suica_update.scpt
-- マネーフォワードのトップ https://moneyforward.com/ を開いて
-- 「電子マネー・プリペイド > モバイルSuica」の「更新」リンクをクリックする
-- 実行時刻と結果を log で出力（cron からリダイレクトしてファイル保存を想定）
-- crontabに定義
-- 30 7 * * * /usr/bin/osascript /Users/46158n/src/moneyforward-suica-auto-update/mf_suica_update.scpt >> /Users/46158n/src/moneyforward-suica-auto-update/mf_suica_update.log 2>&1

property mfUrl : "https://moneyforward.com/"

on run argv
    -- ログ用の現在時刻文字列
    set nowStr to do shell script "date '+%Y-%m-%d %H:%M:%S'"

    try
        ------------------------------------------------------------------
        -- 1. Chromeでマネーフォワードのトップを新しいタブで開く
        ------------------------------------------------------------------
        tell application "Google Chrome"
            activate

            if (count of windows) = 0 then
                make new window
            end if

            tell front window
                set newTab to make new tab with properties {URL:mfUrl}
                set active tab index to (count of tabs)
            end tell
        end tell

        ------------------------------------------------------------------
        -- 2. ページ読み込み待ち（必要に応じて秒数は調整）
        ------------------------------------------------------------------
        delay 5

        ------------------------------------------------------------------
        -- 3. 「モバイルSuica」の行を探して「更新」リンクをクリックするJS
        ------------------------------------------------------------------
        set jsCode to "
(function() {
  try {
    // 「登録金融機関」セクション内の li.account を全部取得
    const accountsSection = document.querySelector('section#registered-accounts');
    if (!accountsSection) return 'no-registered-accounts-section';

    const accounts = Array.from(accountsSection.querySelectorAll('li.account'));
    if (!accounts.length) return 'no-accounts';

    // テキストに「モバイルSuica」を含む行を探す
    const suicaItem = accounts.find(li => li.innerText.includes('モバイルSuica'));
    if (!suicaItem) return 'suica-not-found';

    // その行の中の <a> から「更新」と書いてあるリンクを探す
    const updateLink = Array.from(suicaItem.querySelectorAll('a'))
      .find(a => a.textContent.trim().includes('更新'));
    if (!updateLink) return 'update-not-found';

    updateLink.click();
    return 'clicked';
  } catch (e) {
    return 'error:' + e;
  }
})();
"

        ------------------------------------------------------------------
        -- 4. アクティブタブでJSを実行して結果を受け取る
        ------------------------------------------------------------------
        set resultText to ""

        tell application "Google Chrome"
            tell front window
                set theTab to active tab
                set resultText to execute theTab javascript jsCode
            end tell
        end tell

        ------------------------------------------------------------------
        -- 5. 実行時刻＋結果をログ出力
        --    例: 2025-11-19 07:30:03 : MobileSuica update result = clicked
        ------------------------------------------------------------------
        log nowStr & " : MobileSuica update result = " & resultText

        -- ------------------------------------------------------
        -- ★ 更新後に少し待ってタブを閉じる
        -- ------------------------------------------------------
        if resultText is "clicked" then
            -- 更新後、3〜5秒程度自然に待つ（好みで調整OK）
            delay 5

            tell application "Google Chrome"
                tell front window
                    set theTab to active tab
                    close theTab
                end tell
            end tell
        end if

    on error errMsg number errNum
        -- 例外発生時も時刻付きでログに残す
        log nowStr & " : ERROR (" & errNum & ") " & errMsg
    end try
end run
