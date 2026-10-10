# Signing the extension for Firefox

Firefox Release and Beta only install extensions that were signed by Mozilla. The files produced by `npm run build:firefox` are not signed, so you need to sign them once per version. Signing as an **unlisted** add-on is free, does not publish anything on addons.mozilla.org and the resulting `.xpi` is only yours to install or share.

There are two ways to get a version signed:

- **Option A: upload it in the Developer Hub (website).** No API keys needed. This is the way this fork is released.
- **Option B: `web-ext sign` (command line).** Needs API keys.

## Requirements

- A free Mozilla developer account at <https://addons.mozilla.org/developers/>
- Option A on Windows: `git` and [`web-ext`](https://extensionworkshop.com/documentation/develop/getting-started-with-web-ext/) (`npm i -g web-ext`), used by `scripts/Build-Release.ps1`
- Option B: `web-ext` as well

`web-ext` needs a recent Node.js. Do not run it from a shell where the Node.js 12 from `.tools/` is first in `PATH` (that Node.js is only for building the interface, see the README).

## Prepare the release

Before signing a new release:

- **Raise the version.** Mozilla refuses a version number that was already signed. In this repo the version comes from `package.json` (also update the two version fields of `package-lock.json`).
- **Keep the add-on ID.** This fork uses `protonmail-webextension@local` (set in `scripts/manifest.js` for the Firefox build). If the ID changes, Firefox treats the new file as a different add-on and does not replace the installed one.
- **Data collection declaration.** The Firefox manifest declares `data_collection_permissions` with `required: ["none"]` (the extension only talks to `mail.proton.me` with your own session). Change it if you ever add something that sends data elsewhere.

Then create the packages. On Windows, from the repository root (needs a clean git working tree):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Release.ps1
```

It builds the extension and creates `release\<version>\firefox-<version>.zip` and `release\<version>\source-<version>.zip`. Without the script, use the `./build` folder after `npm run build:firefox` (or the contents of a Firefox zip) as the folder to sign. In both cases `manifest.json` must be directly in the root of the folder or zip.

## Option A: upload in the Developer Hub

1. Open the **versions page of your add-on** in the Developer Hub (My Add-ons > the extension > Manage Status & Versions) and click **Upload New Version**.
   - Use this for every release after the first one. "Submit a New Add-on" creates a new add-on and fails with "Duplicate add-on ID found".
   - For the very first release use "Submit a New Add-on".
2. Choose **On your own** (unlisted).
3. Upload `firefox-<version>.zip` and wait for the validation. Warnings do not block unlisted add-ons, only errors do.
4. The question about source code: answer **Yes** (the extension is built with webpack and `react-scripts`) and upload `source-<version>.zip`.
5. Wait for the e-mail saying the version was approved (usually about a minute, up to 24 hours).
6. Download the signed `.xpi` from the versions page and keep it in `release\<version>\signed\`.

## Option B: sign with `web-ext`

### 1. Create API keys

1. Open <https://addons.mozilla.org/developers/addon/api/key/> and generate credentials.
2. You get a **JWT issuer** (looks like `user:1234567:89`) and a **JWT secret**.
3. The secret is shown only once. Use the copy icon next to it instead of selecting the text by hand, because the field is narrow and cuts the value.
4. Never commit the keys, paste them in issues or share screenshots that show them. If that happens, revoke them and generate new ones.
5. Mozilla limits how often credentials can be generated ("You have submitted this form too many times recently"). If you hit the limit, wait or use Option A.

### 2. Sign

```powershell
# API credentials from addons.mozilla.org (JWT issuer / JWT secret)
$env:WEB_EXT_API_KEY    = "user:1234567:89"
$env:WEB_EXT_API_SECRET = "<jwt secret>"

# Sign as an unlisted add-on; the signed .xpi is written to the artifacts dir
web-ext sign --channel=unlisted --source-dir .\build --artifacts-dir .\release\signed
```

The values above are only an example of the format. Put the value only between the quotes, without `<` and `>`. The command uploads the folder, waits for the automatic validation and downloads the signed file. When you are done, revoke the keys on the same page.

### Optional: helper script

This asks for the keys instead of storing them in the file. It is a convenience example and was not tested on every setup.

```powershell
# Sign-FirefoxExtension.ps1
param(
    [string]$SourceDir    = ".\build",
    [string]$ArtifactsDir = ".\release\signed"
)

$env:WEB_EXT_API_KEY = Read-Host "JWT issuer"
$secure = Read-Host "JWT secret" -AsSecureString
$bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$env:WEB_EXT_API_SECRET = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

try {
    web-ext sign --channel=unlisted --source-dir $SourceDir --artifacts-dir $ArtifactsDir
}
finally {
    # Do not leave the credentials in the environment
    Remove-Item Env:WEB_EXT_API_KEY, Env:WEB_EXT_API_SECRET -ErrorAction SilentlyContinue
}
```

## Install

1. In Firefox open `about:addons`.
2. Click the gear icon and choose **Install Add-on From File...**.
3. Select the signed `.xpi`. You can also drag it into the window.
4. If you had the extension loaded temporarily from `about:debugging`, remove it first (same ID).
5. Check the version in `about:addons` and in the extension settings.

## Updating

Unlisted add-ons do not update themselves. For each new version: raise the version number, create the packages, get them signed (Option A or B) and install the new `.xpi` over the old one. Your settings are kept as long as the ID is the same.

## Troubleshooting

| Message / symptom | Cause and fix |
| --- | --- |
| "This add-on could not be installed because it has not been verified" | The file is not signed. Sign it or use one of the alternatives in the README. |
| "Duplicate add-on ID found" | You used "Submit a New Add-on". Use **Upload New Version** on the existing add-on. |
| Version already exists | That version number was already signed. Raise it in `package.json` and build again. |
| JavaScript syntax error in validation | A built file was edited by hand and got corrupted (the files are minified, one line). Do not edit them, rebuild instead. |
| Installs as a second extension | The add-on ID is different. Check `browser_specific_settings.gecko.id` in `manifest.json`. |
| "You have submitted this form too many times recently" | Rate limit when generating API keys. Wait, or use Option A. |
| Authentication error from `web-ext` | Wrong or truncated JWT issuer/secret, or the keys were revoked. Generate new ones. |
| `web-ext` fails with syntax errors | It is running under Node.js 12. Run it from a shell with a recent Node.js. |
| Validation warnings (`eval`, `innerHTML`, known library) | They come from bundled libraries and do not block unlisted add-ons. |
