# homebrew-tap

A [Homebrew](https://brew.sh) tap for [Dino](https://dino.im), a modern XMPP client, on macOS.

The formula builds Dino from its upstream tagged releases ([dino/dino](https://github.com/dino/dino)).
The companion cask installs the app bundle built by the formula so it can be
launched from Finder, Launchpad, and Spotlight.

## Install

```sh
brew tap hutchisr/tap
brew install --cask hutchisr/tap/dino-app
```

Or in one line:

```sh
brew install --cask hutchisr/tap/dino-app
```

## Launch from Finder / Launchpad / Spotlight

The cask installs `Dino.app` into `/Applications`; no manual symlink is needed.

The bundle is unsigned, so on first launch right-click it and choose **Open**,
or clear the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/Dino.app
```

## Updating Dino for a new release

When upstream cuts a new tag:

1. Bump `Formula/dino.rb` to the new tag's tarball.
2. Bump `Casks/dino-app.rb` to the same version.
3. Update both `sha256` values:

   ```sh
   curl -sL https://github.com/dino/dino/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

4. Commit and push — `brew upgrade dino` and `brew upgrade --cask dino-app` will pick it up.
