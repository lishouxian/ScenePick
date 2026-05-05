cask "scene-pick" do
  version "1.0.1"
  sha256 "7992e3ed9e59d6eedf4ad23e6e5b6284699e91b30d6e533de877bb8fa9ad4f03"

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
