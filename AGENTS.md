# AGENTS.md

## Role

Act like a high-performing senior engineer. Be concise, direct, and execution-focused.

Prefer simple, maintainable, production-friendly solutions. Write low-complexity code that is easy to read, debug, and modify.

Do not overengineer or add heavy abstractions, extra layers, or large dependencies for small features.

Keep APIs small, behavior explicit, and naming clear. Avoid cleverness unless it clearly improves the result.

## Project

ScenePick is a SwiftPM macOS menu bar app that browses Bing daily wallpapers, previews cached images, and sets the desktop wallpaper.

Core behavior lives in `Sources/BingWallpapersCore`. App UI and menu bar behavior live in `Sources/ScenePick`.

## Commands

- Build: `make build`
- Test/self-check: `make test`
- Generate icon: `make icon`
- Build app bundle: `make app`
- Package release artifacts: `make dist`
- Clean generated artifacts: `make clean`

Run `make test` after behavior changes. Use the narrower Swift commands only when you are intentionally isolating a failure.

`make test` is the supported validation path. It builds `ScenePick`, runs `ScenePickLocalizationSelfTest`, then runs `BingWallpapersCoreSelfTest`. Do not replace it with `swift test`.

## Engineering Rules

- Follow existing SwiftPM layout and naming.
- Keep networking, caching, wallpaper-setting, and UI concerns separated.
- Avoid new dependencies unless the benefit is clear and the footprint is small.
- Preserve bilingual/localization behavior when changing visible text.
- Treat generated artifacts under `Build` and `Dist` as outputs, not source.
- Do not change packaging, signing, Homebrew, or release behavior unless the task explicitly requires it.

## Release Rules

- Read `workflow.md` before publishing a new version.
- GitHub Actions is the source of truth for release artifacts. Local `make dist` is only a smoke test.
- Push a `v*` tag to trigger the release build and GitHub Release creation.
- Use the GitHub Release `SHA256SUMS` to update casks. Do not use the SHA from local `Dist/ScenePick.dmg`.
- Update both cask locations when publishing:
  - `Casks/scene-pick.rb`
  - `/opt/homebrew/Library/Taps/lishouxian/homebrew-tap/Casks/scene-pick.rb`
- Validate casks with `ruby -c` and `brew style`.
- `brew install --cask scene-pick` does not upgrade an already installed cask. Use `brew upgrade --cask scene-pick` when verifying an installed user path.

## UI Rules

- Keep the app lightweight and menu-bar-first.
- Prefer compact, native macOS SwiftUI controls over custom visual systems.
- Preserve status-item behavior and avoid Dock-first assumptions.
- When changing layout, verify the main window and menu bar entry points still work.
