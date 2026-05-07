cask "scene-pick" do
  version "1.0.3"
  sha256 "5cda629c9e6ccdcfebe89279e47ae506bbabfebb164000c6f2fb79f7ab1493f7"

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
