# MOFU デプロイスクリプト
# 使い方: PowerShellで ./deploy.ps1 を実行

Write-Host "🐾 MOFUをデプロイします..." -ForegroundColor Cyan

# masterブランチにいることを確認
$branch = git branch --show-current
if ($branch -ne "master") {
    git checkout master
}

# 変更をコミット＆プッシュ → GitHub Actionsが自動ビルド
$msg = Read-Host "コミットメッセージを入力（Enterでデフォルト）"
if ([string]::IsNullOrEmpty($msg)) {
    $msg = "Update MOFU app"
}

git add -A
git commit -m $msg
git push origin master

Write-Host "✅ プッシュ完了！GitHub Actionsが自動でビルド・デプロイします" -ForegroundColor Green
Write-Host "📍 進捗確認: https://github.com/catlisa332/mofu-app/actions" -ForegroundColor Yellow
Write-Host "🌐 公開URL: https://catlisa332.github.io/mofu-app/" -ForegroundColor Yellow
