# cl_video_player

Shared video-player layer used by the Ice Hockey Maharashtra Flutter app and sibling packages. This repo is consumed both standalone and as a git submodule of the `icehockey_mh_app` workspace.

## Flutter SDK (FVM)

The Flutter SDK version is pinned in `.fvmrc` (currently 3.41.9). Always invoke Flutter through FVM so the pinned version is used and `pubspec.lock` files stay stable:

- Use `fvm flutter ...` and `fvm dart ...` for any command that needs Flutter or Dart (`pub get`, `pub upgrade`, `build`, `run`, `test`, `analyze`, etc.).
- Plain `flutter` / `dart` are acceptable only if the global FVM version (`fvm global`) matches `.fvmrc`; otherwise prefix with `fvm` to be safe.
- If `pubspec.lock` shows unexpected transitive-dep changes (notably `matcher` / `test_api`), it's almost certainly a wrong-SDK invocation — re-run with `fvm flutter pub get` before committing.
