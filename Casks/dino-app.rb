cask "dino-app" do
  version "0.5.1"
  sha256 "2658b83abe1203b2dd4d6444519f615b979faaac7e97f384e655bff85769584b"

  url "https://github.com/dino/dino/archive/refs/tags/v#{version}.tar.gz"
  name "Dino"
  desc "Modern XMPP client (installs the app bundle built by the dino formula)"
  homepage "https://dino.im/"

  depends_on formula: "hutchisr/tap/dino"
  depends_on :macos

  app "Dino.app"

  # Casks can't build from source and Dino ships no macOS binaries, so the
  # dino formula does the building (including the Dino.app wrapper bundle in
  # its keg). Formulae are sandboxed and can't write to /Applications, but
  # casks aren't - so this cask stages a copy of the keg's bundle for the
  # `app` artifact to install (preflight blocks always run before artifacts,
  # regardless of stanza order). The url above is only used for
  # version/checksum bookkeeping; its download is not what gets installed.
  preflight do
    system_command "/usr/bin/ditto",
                   args: ["#{HOMEBREW_PREFIX}/opt/dino/Dino.app", "#{staged_path}/Dino.app"]
  end

  zap trash: "~/.local/share/dino"
end
