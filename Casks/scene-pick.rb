cask "scene-pick" do
  version "1.0.6"
  sha256 "35496760862e3925b4266789f50cffdf4671426609c56a03748ab528471103fe"

  url "https://github.com/lishouxian/ScenePick/releases/download/v#{version}/ScenePick.dmg"
  name "ScenePick"
  name "拾景"
  desc "Browse Bing daily wallpapers and set the desktop background"
  homepage "https://github.com/lishouxian/ScenePick"

  depends_on macos: :ventura

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
