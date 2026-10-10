![ProtonMail Unofficial Webextension icon](public/icons/logo-152.png)

# Protonmail Unofficial Webextension

Browser extension that lists your ProtonMail accounts, shows the unread count as a toolbar badge and lets you peek at or open your inbox from the popup.

This repository is a fork of [Scallywer/protonmail-webextension](https://github.com/Scallywer/protonmail-webextension), which is itself a fork of the original [gitladen7/protonmail-webextension](https://github.com/gitladen7/protonmail-webextension). The original authorship and commit history are preserved.

## Changes in this fork (version 1.20.3)

- **Unread badge fixed.** The unread count is now fetched explicitly once per check (`src/background/services/emailFetcherService.ts`). Previously it was only requested on the first load and afterwards depended on the `Unread.Locations` field of the event stream, which the ProtonMail API no longer reliably sends, so the badge stayed stale or empty. The legacy event branch is now guarded so that an unexpected payload can no longer abort the whole check.
- **`.onion` domain removed.** `src/shared/protonDomains.js` now only lists `mail.proton.me`.
- **New icon set.** All files in `public/icons/` were replaced (PNG sizes, light/dark SVG and `logo-152.png`).
- **Firefox package.** The Firefox build uses SVG icons with light/dark variants and a fixed add-on ID in `browser_specific_settings`.

Only the Firefox package of this version was tested. The Chromium build was not rebuilt for 1.20.3.

## Download
Please build your own or if you insist, you can download the compiled zips from the root folder. Those zips are the ones published by the previous maintainers and do not include the changes listed above.
Current plugins available as extensions are now working because the ProtonMail changed the domain.

## Building
run `npm i && npm run build:firefox` or `npm i && npm run build:chromium`. Extension will compile to ./build, run `npm run deploy` to create the packed extensions zip.

Notes:
- The toolchain is old (`react-scripts` 3.2, `node-sass` 4, webpack 4). On a recent Node.js the build may fail unless you set `NODE_OPTIONS=--openssl-legacy-provider`, and `node-sass` may not compile at all.
- `npm run deploy` refuses to run with uncommitted changes.

## Installing in Firefox
Release and Beta versions of Firefox only install signed extensions. The build output is **not** signed, so you have these options:

- **Recommended: sign it yourself as an unlisted add-on.** It is free, nothing is published, and the signed `.xpi` installs permanently in regular Firefox. Step by step guide: [docs/SIGNING.md](docs/SIGNING.md). Every new version needs a higher version number and a new signature.
- Use Firefox Developer Edition, Nightly or ESR with `xpinstall.signatures.required` set to `false` in `about:config`. This setting is ignored in Release and Beta.
- Load it temporarily from `about:debugging#/runtime/this-firefox` ("Load Temporary Add-on"). Good for testing only: it is removed when Firefox closes.

## Disclaimer
This is an unofficial extension and is not affiliated with Proton AG. It reads your ProtonMail session data (cookies and requests to `mail.proton.me`) in order to work.
