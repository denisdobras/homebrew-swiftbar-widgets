class ChargingWattage < Formula
  desc "SwiftBar plugin showing live charging wattage in the macOS menu bar"
  homepage "https://github.com/denisdobras/homebrew-swiftbar-widgets"
  url "https://github.com/denisdobras/homebrew-swiftbar-widgets/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "5020a9b103adbeea6c58ca2051e9cf74363ee23c6abb9d06201d2dc04bd5d0ee"
  license "MIT"
  version "1.1.0"

  def install
    (share/"swiftbar-plugins").install "charging-wattage.3s.sh"
  end

  def caveats
    <<~EOS
      Make sure SwiftBar is installed:
        brew install --cask swiftbar
        open -a SwiftBar

      Link the plugin into SwiftBar's plugin folder:
        SBDIR="$HOME/Library/Application Support/SwiftBar"
        mkdir -p "$SBDIR"
        ln -sf #{opt_share}/swiftbar-plugins/charging-wattage.3s.sh "$SBDIR/"

      Then point SwiftBar at $SBDIR via Preferences → Plugins Folder,
      or refresh via the SwiftBar menu icon.
    EOS
  end

  test do
    assert_predicate share/"swiftbar-plugins/charging-wattage.3s.sh", :executable?
  end
end
