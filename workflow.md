# ScenePick 发布流程

本文档记录 ScenePick 的小版本发布流程。发布包由 GitHub Actions 在远端 macOS runner 上构建，本地只负责改代码、打 tag、验证 Release 产物和更新 Homebrew tap。

## 相关文件

- `.github/workflows/build.yml`：GitHub Actions 发布入口。
- `Scripts/build-app.sh`：构建 `Build/ScenePick.app`，写入 bundle 版本和本地化 `InfoPlist.strings`。
- `Scripts/package-release.sh`：生成 `Dist/ScenePick.dmg`、`Dist/ScenePick.zip`、`Dist/SHA256SUMS`。
- `Sources/ScenePickLocalizationSelfTest/main.swift`：检查打包后的本地化资源是否能正确输出中英文地区、填充方式和预览文案。
- `Casks/scene-pick.rb`：主仓库内保留的 cask 副本。
- `/opt/homebrew/Library/Taps/lishouxian/homebrew-tap/Casks/scene-pick.rb`：Homebrew 用户实际安装用的 tap cask。

## Actions 行为

`Build` workflow 会在以下场景运行：

- push 到 `main`：运行测试、打包、上传 artifact，不创建 GitHub Release。
- push `v*` tag：运行测试、打包、上传 artifact，并创建 GitHub Release。
- pull request / 手动触发：用于验证。

tag 发布时，workflow 会把 `APP_VERSION` 设置为 tag 去掉 `v` 后的版本号，例如 `v1.0.2` 会写入 `1.0.2`。`APP_BUILD` 使用 `github.run_number`，所以最终 bundle build number 以 Actions 为准，本地 `Scripts/build-app.sh` 里的默认值只是本地 fallback。

## 发布步骤

1. 确认工作区和远端状态。

```bash
git status --short --branch
git fetch --tags origin
git tag --sort=-v:refname | head
```

2. 修改代码和版本默认值。

至少更新：

- 业务代码或文案。
- `Scripts/build-app.sh` 里的默认 `APP_VERSION`。
- 如需要，本地默认 `APP_BUILD` 顺手递增；实际发布 build number 仍以 Actions 为准。

3. 本地验证。

```bash
make test
make build
```

`make dist` 可作为本地打包 smoke test，但不要用本地 `Dist/ScenePick.dmg` 的 SHA 更新 Homebrew tap。最终 cask checksum 必须来自 GitHub Release 资产。

`make test` 目前会先构建 `ScenePick`，再运行 `ScenePickLocalizationSelfTest` 和 `BingWallpapersCoreSelfTest`；不要用 `swift test` 替代它。

4. 提交并推送 `main`。

```bash
git add <changed-files>
git commit -m "Prepare ScenePick 1.0.2 release"
git push origin main
```

5. 创建并推送 tag。

```bash
git tag -a v1.0.2 -m "ScenePick v1.0.2"
git push origin v1.0.2
```

6. 监控 tag workflow。

```bash
gh run list --workflow Build --branch v1.0.2 --limit 1
gh run watch <run-id> --exit-status
```

成功后应有一个 GitHub Release，包含：

- `ScenePick.dmg`
- `ScenePick.zip`
- `SHA256SUMS`

7. 下载 Release 校验和。

```bash
rm -rf /tmp/scenepick-v1.0.2-release
mkdir -p /tmp/scenepick-v1.0.2-release

gh release download v1.0.2 \
  --pattern SHA256SUMS \
  --pattern ScenePick.dmg \
  --dir /tmp/scenepick-v1.0.2-release \
  --clobber

cd /tmp/scenepick-v1.0.2-release
shasum -a 256 -c SHA256SUMS --ignore-missing
```

从 `SHA256SUMS` 里取 `ScenePick.dmg` 对应的 SHA256。

8. 更新主仓库 cask 副本。

```bash
# 在 ScenePick 主仓库
vim Casks/scene-pick.rb
ruby -c Casks/scene-pick.rb
brew style Casks/scene-pick.rb

git add Casks/scene-pick.rb
git commit -m "Update cask for ScenePick 1.0.2"
git push origin main
```

9. 更新 Homebrew tap。

```bash
cd /opt/homebrew/Library/Taps/lishouxian/homebrew-tap
git pull --ff-only

vim Casks/scene-pick.rb
ruby -c Casks/scene-pick.rb
brew style Casks/scene-pick.rb

git add Casks/scene-pick.rb
git commit -m "Update ScenePick cask to 1.0.2"
git push origin main
```

tap cask 的 `version` 和 `sha256` 必须与 GitHub Release 的 DMG 匹配。

10. 验证 Homebrew 用户路径。

```bash
brew update
brew info --cask scene-pick
brew cat --cask scene-pick | sed -n '1,12p'
brew upgrade --cask scene-pick
brew list --cask --versions scene-pick
```

已安装用户应使用 `brew upgrade --cask scene-pick`。`brew install --cask scene-pick` 对已安装 cask 不会升级，只会提示 latest version is already installed 或不执行升级。

## 常见问题

- Homebrew 仍显示旧版本：先确认 `/opt/homebrew/Library/Taps/lishouxian/homebrew-tap/Casks/scene-pick.rb` 是否已更新并推送，而不是只更新了 ScenePick 主仓库里的 cask 副本。
- Cask SHA 不匹配：不要用本地 `make dist` 的 DMG SHA，重新下载 GitHub Release 的 `SHA256SUMS`。
- Release 没创建：确认推送的是 `v*` tag，不是只 push 到 `main`。
- bundle 版本不符合预期：检查 tag 名和 Actions run number；发布时 `CFBundleShortVersionString` 来自 tag，`CFBundleVersion` 来自 `github.run_number`。
