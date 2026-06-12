# homebrew-tap

A [Homebrew](https://brew.sh) tap for [Dino](https://dino.im), a modern XMPP client, on macOS.

The formulae build Dino from source ([dino/dino](https://github.com/dino/dino)) and wrap the
result in a proper macOS `.app` bundle, with a few macOS-specific fixes patched in:

- **Native notifications** — the binary is exec'd from inside the bundle so GLib's Cocoa
  notification backend works, and notifications are re-posted in a way that banners on
  every message (not just the first per conversation).
- **Image previews** — backports upstream's UTI-vs-MIME-type fix to the release build,
  without which previews never render on macOS.
- **Working plugins** (OMEMO etc.) — plugins are built with the `.so` suffix GLib's module
  loader expects on macOS.

## Install

```sh
brew install --cask hutchisr/tap/dino-app
```

This builds the `dino` formula from source and installs `Dino.app` into `/Applications`,
launchable from Finder, Launchpad, and Spotlight. The app in `/Applications` execs the
current keg's binary through a stable `opt` symlink, so `brew upgrade dino` takes effect
without reinstalling the cask. (Reinstall the cask only if the bundle itself — launcher,
icon, Info.plist — changes.)

Formula only (keg-side `Dino.app` plus the `dino` CLI, nothing in `/Applications`):

```sh
brew install hutchisr/tap/dino
```

## Nightly builds

`dino-nightly` tracks upstream master, pinned to a commit that a
[daily workflow](.github/workflows/bump-dino-nightly.yml) bumps automatically.
It is keg-only and coexists with the release formula:

```sh
brew install --cask hutchisr/tap/dino-nightly-app   # "Dino Nightly.app" in /Applications
```

Both variants share the same profile (`~/.local/share/dino`). Each switch between them
migrates the database schema in place, and downgrading back to the release drops any
columns the older schema doesn't know about — avoid alternating between them routinely.

## Updating the release formula

When upstream cuts a new tag:

1. Bump the `url` to the new tag's tarball and update `sha256`:

   ```sh
   curl -sL https://github.com/dino/dino/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

2. Drop the `revision` line and check whether the patched `inreplace` lines still apply —
   in particular, the image-preview backport should be removed once a release contains
   upstream's `FileContentType` fix (dino/dino commit `5fb3de64`).
3. Bump `version` and `sha256` in `Casks/dino-app.rb` to match.
4. Commit and push — `brew upgrade dino` picks it up.

The nightly formula needs no manual care; CI bumps it daily, and build-logic changes
should be kept in sync between `Formula/dino.rb` and `Formula/dino-nightly.rb`.
