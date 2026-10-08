#!/bin/bash
# hexo-admin 一键发布脚本：本地构建验证 -> 提交源码 -> 推送触发 GitHub Actions 自动部署
cd "$(dirname "$0")" || exit 1
export PATH="$HOME/Library/nodejs/current/bin:$PATH"

echo "[1/3] 本地构建验证..."
if ! npx hexo generate; then
  echo "❌ 构建失败，已取消发布（请检查文章格式）"
  exit 1
fi

echo "[2/3] 提交源码..."
git add -A
if git diff --cached --quiet; then
  echo "✅ 没有新的更改需要发布"
  exit 0
fi
git commit -m "publish: $(date '+%Y-%m-%d %H:%M') via hexo-admin" || exit 1

echo "[3/3] 推送到 GitHub..."
if git push origin main; then
  echo "✅ 发布成功！GitHub Actions 正在自动构建，约 1 分钟后网站更新"
  echo "   访问: https://3322888.xyz"
else
  echo "❌ 推送失败，请检查网络或 SSH 配置"
  exit 1
fi
