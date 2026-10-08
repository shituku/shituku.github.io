#!/bin/bash
# hexo-admin 一键发布脚本：构建并部署到 GitHub Pages
cd "$(dirname "$0")" || exit 1
export PATH="$HOME/Library/nodejs/current/bin:$PATH"
npx hexo generate && npx hexo deploy
