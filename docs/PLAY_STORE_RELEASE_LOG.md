# Play Store Release Log

A chronological record of every build uploaded to Google Play Console for Aqua Sort.
**Keep this file updated with every release.**

---

## Release v1.2.0+7 — Production (R8-protected)

- **versionName**: `1.2.0`
- **versionCode**: `7`
- **Track**: Production
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (77.5 MB)
- **Mapping file** (deobfuscation): `KeyStore/mapping-1.2.0+7.txt` (27 MB)
- **R8 minification**: ✅ Enabled (`isMinifyEnabled = true`, `isShrinkResources = true`)
- **37,151** classes/methods stripped by R8
- **Note**: Bumped from `+6` to `+7` because version code 6 was already taken on the production track. User-facing version `1.2.0` unchanged.
- **Notes**: Full AdMob integration. R8/ProGuard enabled for the first time on production.

---

## Release v1.1.0+5 — Closed Testing (completed)

- **versionName**: `1.1.0`
- **versionCode**: `5`
- **Track**: Closed testing
- **Duration**: 20 days
- **Testers**: 12
- **Status**: ✅ Completed
- **Note**: Pre-AdMob release. R8 was disabled at this time.

---

## General Release Workflow (for future versions)

1. Update `version` in `pubspec.yaml` (e.g. `1.3.0+8`)
2. Run `flutter build appbundle --release`
3. Upload AAB to Play Console
4. Upload mapping file from `build/app/outputs/mapping/release/mapping.txt`
5. Copy mapping to `KeyStore/mapping-<versionName>+<versionCode>.txt` for backup
6. Add a new entry to this log
7. Commit the mapping file backup to a secure private location

**Why keep the mapping file?**
The mapping file is **version-specific** and **cannot be regenerated**.
Without it, you can never deobfuscate crash reports and ANRs from that specific release.
Losing it means losing the ability to read stack traces from production users.
