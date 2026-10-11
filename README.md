![ProtonMail Unofficial Webextension icon](public/icons/logo-152.png)

# Protonmail Unofficial Webextension

Browser extension that lists your ProtonMail accounts, shows the unread count as a toolbar badge and lets you peek at or open your inbox from the popup.

This repository is a fork of [Scallywer/protonmail-webextension](https://github.com/Scallywer/protonmail-webextension), which is itself a fork of the original [gitladen7/protonmail-webextension](https://github.com/gitladen7/protonmail-webextension). The original authorship and commit history are preserved.

## Changes in this fork (version 1.20.4)

- **Unread badge fixed.** The unread count is now fetched explicitly once per check (`src/background/services/emailFetcherService.ts`). Previously it was only requested on the first load and afterwards depended on the `Unread.Locations` field of the event stream, which the ProtonMail API no longer reliably sends, so the badge stayed stale or empty. The legacy event branch is now guarded so that an unexpected payload can no longer abort the whole check.
- **`.onion` domain removed.** `src/shared/protonDomains.js` now only lists `mail.proton.me`.
- **New icon set.** All files in `public/icons/` were replaced (PNG sizes, light/dark SVG and `logo-152.png`).
- **Firefox manifest.** The Firefox build uses SVG icons with light/dark variants, a fixed add-on ID and declares `data_collection_permissions` as `none` in `browser_specific_settings` (`scripts/manifest.js`). The extension homepage now points to this fork.
- **Version in the settings.** The version shown in the extension settings matches the release, it is read from `package.json` when building.
- **Reproducible builds.** `.gitattributes` forces LF line endings and `scripts/Build-Release.ps1` builds the release packages with a portable Node.js 12 (see Building). Signing and uploading to addons.mozilla.org is described in [docs/SIGNING.md](docs/SIGNING.md).
- **Prebuilt zips removed** from the working tree (still in the git history).

Only the Firefox package of this version was tested. The Chromium build was not rebuilt for 1.20.4.

## Download
There are no prebuilt packages in this repository, please build your own (see below). The compiled zips published by the previous maintainers were removed from the working tree, they are still available in the git history.
Current plugins available as extensions are now working because the ProtonMail changed the domain.

## Building
run `npm i && npm run build:firefox` or `npm i && npm run build:chromium`. Extension will compile to ./build, run `npm run deploy` to create the packed extensions zip.

Notes:
- The lockfile pins `node-sass` 4.12.0, which only works with Node.js 12 (tested with 12.22.12). On newer Node.js versions the interface build fails.
- Windows: `scripts/Build-Release.ps1` downloads a portable Node.js 12 into `.tools/` (ignored by git), builds the Firefox extension and creates `release/<version>/firefox-<version>.zip` and `source-<version>.zip`, ready to upload to addons.mozilla.org. It needs `git`, `web-ext` (installed globally) and a clean working tree. Use it instead of `npm run deploy`: the source zip made by `deploy` also picks up untracked folders such as `.tools/`.
- `.gitattributes` forces LF line endings. Some source files are embedded in `background.js` at build time, so a CRLF checkout (the default of Git for Windows) produces a slightly different build.
- `npm run deploy` refuses to run with uncommitted changes.

## Installing in Firefox
Release and Beta versions of Firefox only install signed extensions. The build output is **not** signed, so you have these options:

- **Recommended: sign it yourself as an unlisted add-on.** It is free, nothing is published, and the signed `.xpi` installs permanently in regular Firefox. Step by step guide: [docs/SIGNING.md](docs/SIGNING.md). Every new version needs a higher version number and a new signature.
- Use Firefox Developer Edition, Nightly or ESR with `xpinstall.signatures.required` set to `false` in `about:config`. This setting is ignored in Release and Beta.
- Load it temporarily from `about:debugging#/runtime/this-firefox` ("Load Temporary Add-on"). Good for testing only: it is removed when Firefox closes.

## Disclaimer
This is an unofficial extension and is not affiliated with Proton AG. It reads your ProtonMail session data (cookies and requests to `mail.proton.me`) in order to work.
