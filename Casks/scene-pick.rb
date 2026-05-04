cask "scene-pick" do
  version :latest
  sha256 :no_check

  url "https://github.com/lishouxian/ScenePick/releases/latest/download/ScenePick.dmg"
  name "ScenePick"
  name "拾景"
  desc "Menu bar app for browsing Bing daily wallpapers and setting the macOS desktop wallpaper"
  homepage "https://github.com/lishouxian/ScenePick"

  app "ScenePick.app"

  zap trash: [
    "~/Library/Application Support/ScenePick",
    "~/Library/Preferences/com.xian.ScenePick.plist",
    "~/Library/Preferences/com.xian.ScenePick.settings.plist",
  ]
end
