# homebrew-tap

A [Homebrew](https://brew.sh) tap for [Dino](https://dino.im), a modern XMPP client, on macOS.

The formula builds Dino from its upstream tagged releases ([dino/dino](https://github.com/dino/dino))
and wraps the result in a proper macOS `.app` bundle so it can be launched from
Finder, Launchpad, and Spotlight.

## Install

```sh
brew tap hutchisr/tap
brew install hutchisr/tap/dino
```

Or in one line:

```sh
brew install hutchisr/tap/dino
```

## Launch from Finder / Launchpad / Spotlight

The install drops a `Dino.app` bundle in the keg but does not link it into
`/Applications`. To make it launchable from the GUI:

```sh
ln -sfn "$(brew --prefix dino)/Dino.app" /Applications/Dino.app
```

The bundle is unsigned, so on first launch right-click it and choose **Open**,
or clear the quarantine flag:

```sh
xattr -dr com.apple.quarantine "$(brew --prefix dino)/Dino.app"
```

## Updating the formula for a new release

When upstream cuts a new tag:

1. Bump the `url` to the new tag's tarball.
2. Update `sha256`:

   ```sh
   curl -sL https://github.com/dino/dino/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

3. Commit and push — `brew upgrade dino` will pick it up.
