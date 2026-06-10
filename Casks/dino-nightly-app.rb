cask "dino-nightly-app" do
  version "0.5.1.20260610"
  sha256 "2ffb2f0b37b8c29361a11a5cb3218532b979bc4767760a8414625148e4523f93"

  url "https://github.com/dino/dino/archive/45723ac201c1905571f9f78c8c970828db97139a.tar.gz"
  name "Dino Nightly"
  desc "Modern XMPP client (installs the app bundle built by the dino-nightly formula)"
  homepage "https://dino.im/"

  livecheck do
    skip "Pinned to upstream master; bumped nightly by CI"
  end

  depends_on formula: "hutchisr/tap/dino-nightly"
  depends_on :macos

  app "Dino Nightly.app"

  # Same arrangement as the dino-app cask: the dino-nightly formula builds
  # the bundle in its keg (formulae are sandboxed and can't write to
  # /Applications), and this cask stages a copy for the `app` artifact to
  # install. The url above (the pinned master commit, kept in sync by
  # .github/workflows/bump-dino-nightly.yml) is only used for
  # version/checksum bookkeeping; its download is not what gets installed.
  preflight do
    system_command "/usr/bin/ditto",
                   args: ["#{HOMEBREW_PREFIX}/opt/dino-nightly/Dino Nightly.app",
                          "#{staged_path}/Dino Nightly.app"]
  end

  zap trash: "~/.local/share/dino"
end
