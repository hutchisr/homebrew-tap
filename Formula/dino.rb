class Dino < Formula
  desc "Modern XMPP client"
  homepage "https://dino.im"
  url "https://github.com/dino/dino/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "2658b83abe1203b2dd4d6444519f615b979faaac7e97f384e655bff85769584b"
  license "GPL-3.0-or-later"
  revision 3

  depends_on "librsvg" => :build # rsvg-convert, to rasterize the app icon
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "adwaita-icon-theme"
  depends_on "cmake"
  depends_on "gettext"
  depends_on "glib"
  depends_on "glib-networking"
  depends_on "gpgme"
  depends_on "gspell"
  depends_on "gstreamer"
  depends_on "gtk+3"
  depends_on "gtk4"
  depends_on "icu4c"
  depends_on "libadwaita"
  depends_on "libgcrypt"
  depends_on "libgee"
  depends_on "libgpg-error"
  depends_on "libnice"
  depends_on "libomemo-c"
  depends_on "libsoup"
  depends_on "libsoup@2"
  depends_on "libxml2"
  depends_on "ninja"
  depends_on "qrencode"
  depends_on "sqlite"
  depends_on "srtp"
  depends_on "vala"

  def install
    # GLib's GModule looks for plugins with the `.so` suffix (Module.SUFFIX)
    # on macOS, but Meson builds shared modules as `.dylib`, so the loader
    # never finds them and encryption (OMEMO) etc. silently go missing.
    # Force the plugins to build with a `.so` suffix. (dino/dino#1830)
    Dir["plugins/*/meson.build"].each do |f|
      inreplace f, "name_prefix: ''", "name_prefix: '', name_suffix: 'so'"
    end

    # On macOS, GLib's g_file_info_get_content_type() returns Apple UTIs
    # ("public.png") rather than MIME types ("image/png"). Dino 0.5.x stores
    # and compares these as if they were MIME types, so image previews never
    # render and sent files are advertised to peers with bogus MIME types.
    # Convert with g_content_type_get_mime_type() (a no-op on Linux).
    # Backport of upstream master's fix (dino/dino commit 5fb3de64,
    # "Handle content type != mime type"); drop once a release contains it.
    inreplace "libdino/src/service/sfs_metadata.vala",
              "metadata.mime_type = info.get_content_type();",
              "metadata.mime_type = ContentType.get_mime_type(info.get_content_type());"
    inreplace "libdino/src/service/sfs_metadata.vala",
              'string mime_type = file.query_info("*", FileQueryInfoFlags.NONE).get_content_type();',
              "string mime_type = ContentType.get_mime_type(" \
              'file.query_info("*", FileQueryInfoFlags.NONE).get_content_type());'
    inreplace "libdino/src/service/file_manager.vala",
              'if (file_info.get_content_type() != "application/octet-stream" || file_transfer.mime_type == null) {',
              'if (ContentType.get_mime_type(file_info.get_content_type()) != "application/octet-stream" ' \
              "|| file_transfer.mime_type == null) {"
    inreplace "libdino/src/service/file_manager.vala",
              "file_transfer.mime_type = file_info.get_content_type();",
              "file_transfer.mime_type = ContentType.get_mime_type(file_info.get_content_type());"
    inreplace "main/src/ui/file_send_overlay.vala",
              "string mime_type = file_info.get_content_type();",
              "string mime_type = ContentType.get_mime_type(file_info.get_content_type());"
    inreplace "main/src/ui/util/file_metadata_providers.vala",
              'string? mime_type = file.query_info("*", FileQueryInfoFlags.NONE).get_content_type();',
              "string? mime_type = ContentType.get_mime_type(" \
              'file.query_info("*", FileQueryInfoFlags.NONE).get_content_type());'

    # Dino reuses the conversation id as the notification id so each
    # conversation keeps a single entry in the notification list. With the
    # legacy NSUserNotificationCenter API that GLib's Cocoa backend uses,
    # delivering a notification whose identifier matches an already-delivered
    # one replaces it in Notification Center WITHOUT presenting a banner - so
    # only the first message of a conversation ever pops. Withdraw first
    # (which removes the delivered entry on the Cocoa backend) so every
    # message banners while still keeping one entry per conversation.
    inreplace "main/src/ui/notifier_gnotifications.vala",
              "GLib.Application.get_default().send_notification(" \
              "conversation.id.to_string(), notifications[conversation]);",
              "GLib.Application.get_default().withdraw_notification(conversation.id.to_string());\n" \
              "            GLib.Application.get_default().send_notification(" \
              "conversation.id.to_string(), notifications[conversation]);"

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"

    build_app_bundle
  end

  # Wrap the installed CLI binary in a proper macOS .app so Dino can be
  # launched from Finder / Launchpad / Spotlight. The bundle is kept in the
  # keg (not auto-linked); see caveats for adding it to /Applications.
  def build_app_bundle
    app = prefix/"Dino.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath

    # Launcher: Finder gives us none of Homebrew's environment, so point GTK
    # at the schemas, pixbuf loaders, GIO TLS modules (needed for XMPP) and
    # GStreamer plugins (calls) before exec'ing the real binary.
    launcher = app/"Contents/MacOS/Dino"
    launcher.write <<~SH
      #!/bin/bash
      export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"
      export XDG_DATA_DIRS="#{HOMEBREW_PREFIX}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      export GSETTINGS_SCHEMA_DIR="#{HOMEBREW_PREFIX}/share/glib-2.0/schemas"
      export GDK_PIXBUF_MODULE_FILE="#{HOMEBREW_PREFIX}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
      export GIO_EXTRA_MODULES="#{HOMEBREW_PREFIX}/lib/gio/modules"
      export GST_PLUGIN_SYSTEM_PATH_1_0="#{HOMEBREW_PREFIX}/lib/gstreamer-1.0"
      exec "$(dirname "$0")/dino-bin" "$@"
    SH
    launcher.chmod 0755

    # See post_install for the Contents/MacOS/dino-bin symlink.

    # Rasterize the scalable app icon into a multi-resolution .icns.
    svg = "main/data/icons/scalable/apps/im.dino.Dino.svg"
    iconset = buildpath/"Dino.iconset"
    iconset.mkpath
    {
      "icon_16x16.png"      => 16,
      "icon_16x16@2x.png"   => 32,
      "icon_32x32.png"      => 32,
      "icon_32x32@2x.png"   => 64,
      "icon_128x128.png"    => 128,
      "icon_128x128@2x.png" => 256,
      "icon_256x256.png"    => 256,
      "icon_256x256@2x.png" => 512,
      "icon_512x512.png"    => 512,
      "icon_512x512@2x.png" => 1024,
    }.each do |name, px|
      system "rsvg-convert", "-w", px.to_s, "-h", px.to_s, svg, "-o", iconset/name
    end
    system "iconutil", "-c", "icns", iconset, "-o", app/"Contents/Resources/dino.icns"

    (app/"Contents/Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key>            <string>Dino</string>
        <key>CFBundleDisplayName</key>     <string>Dino</string>
        <key>CFBundleIdentifier</key>      <string>im.dino.Dino</string>
        <key>CFBundleExecutable</key>      <string>Dino</string>
        <key>CFBundleIconFile</key>        <string>dino</string>
        <key>CFBundlePackageType</key>     <string>APPL</string>
        <key>CFBundleShortVersionString</key> <string>#{version}</string>
        <key>CFBundleVersion</key>         <string>#{version}</string>
        <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
        <key>LSApplicationCategoryType</key> <string>public.app-category.social-networking</string>
        <key>LSMinimumSystemVersion</key>  <string>11.0</string>
        <key>NSHighResolutionCapable</key> <true/>
      </dict>
      </plist>
    XML
  end

  # GLib's Cocoa notification backend refuses to post unless the running
  # executable lives inside an app bundle ([NSBundle mainBundle] has no
  # bundleIdentifier otherwise), so native macOS notifications only work
  # if we exec the binary from a path within the bundle. A symlink works:
  # NSBundle uses the exec'd path without resolving symlinks. Pointing it
  # at the opt path (stable across upgrades) means the bundle the dino-app
  # cask copies into /Applications keeps running the current keg's binary
  # without a cask reinstall after upgrades. Created in post_install because
  # the install step relativizes in-prefix symlinks inside the keg, and the
  # relative form breaks once the cask dittos the bundle to /Applications
  # (different directory depth). Named "dino-bin" because APFS is
  # case-insensitive and "dino" would collide with the "Dino" launcher.
  def post_install
    ln_sf opt_bin/"dino", prefix/"Dino.app/Contents/MacOS/dino-bin"
  end

  def caveats
    <<~EOS
      A macOS application bundle was installed to:
        #{opt_prefix}/Dino.app

      To install it into /Applications (formulae are sandboxed and cannot
      write there themselves), use the companion cask:
        brew install --cask hutchisr/tap/dino-app

      Or symlink it manually (this path is stable across upgrades):
        ln -sfn #{opt_prefix}/Dino.app /Applications/Dino.app
    EOS
  end

  test do
    # Keep the test run away from the user's real ~/.local/share/dino -
    # dino opens (and migrates!) its database even for --version.
    ENV["XDG_DATA_HOME"] = (testpath/"xdg").to_s
    system "#{bin}/dino", "--version"
    assert_path_exists prefix/"Dino.app/Contents/MacOS/Dino"
    assert_path_exists prefix/"Dino.app/Contents/MacOS/dino-bin"
    assert_path_exists prefix/"Dino.app/Contents/Resources/dino.icns"
  end
end
