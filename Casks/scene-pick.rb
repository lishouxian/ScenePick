cask "scene-pick" do
  version "1.0.2"
  sha256 "df8a9341d923bdc8c1b107673cc4ddbe242f73f73e85ff13c8f841bf4ae94222"

  url "https://github.com/lishouxian/ScenePick/releases/download/v#{version}/ScenePick.dmg"
  name "ScenePick"
  name "拾景"
  desc "Browse Bing daily wallpapers and set the desktop background"
  homepage "https://github.com/lishouxian/ScenePick"

  depends_on macos: ">= :ventura"

  app "ScenePick.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/ScenePick.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/ScenePick",
    "~/Library/Preferences/com.xian.ScenePick.plist",
    "~/Library/Preferences/com.xian.ScenePick.settings.plist",
  ]
end
