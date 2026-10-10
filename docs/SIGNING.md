# Signing the extension for Firefox

Firefox Release and Beta only install extensions that were signed by Mozilla. The files produced by `npm run build:firefox` are not signed, so you need to sign them once per version. Signing as an **unlisted** add-on is free, does not publish anything on addons.mozilla.org and the resulting `.xpi` is only yours to install or share.

## Requirements

- Node.js and npm
- [`web-ext`](https://extensionworkshop.com/documentation/develop/getting-started-with-web-ext/): `npm i -g web-ext`
- A free Mozilla developer account at <https://addons.mozilla.org/developers/>

## 1. Create API keys

1. Open <https://addons.mozilla.org/developers/addon/api/key/> and generate credentials.
2. You get a **JWT issuer** (looks like `user:1234567:89`) and a **JWT secret**.
3. The secret is shown only once. Use the copy icon next to it instead of selecting the text by hand, because the field is narrow and cuts the value.
4. Never commit the keys, paste them in issues or share screenshots that show them. If that happens, revoke them and generate new ones.

## 2. Prepare the folder to sign

The folder must contain `manifest.json` directly in its root. Use either:

- the `./build` folder after `npm run build:firefox`, or
- the contents of a Firefox zip extracted to a folder.

Before signing a new release:

- **Raise the version.** Mozilla refuses a version number that was already signed. In this repo the version comes from `package.json`.
- **Keep the add-on ID.** This fork uses `protonmail-webextension@local` (set in `scripts/manifest.js` for the Firefox build). If the ID changes, Firefox treats the new file as a different add-on and does not replace the installed one.

## 3. Sign

```powershell
# API credentials from addons.mozilla.org (JWT issuer / JWT secret)
$env:WEB_EXT_API_KEY    = "user:1234567:89"
$env:WEB_EXT_API_SECRET = "<jwt secret>"

# Sign as an unlisted add-on; the signed .xpi is written to the artifacts dir
web-ext sign --channel=unlisted --source-dir .\build --artifacts-dir .\signed
```

The values above are only an example of the format. Put the value only between the quotes, without `<` and `>`.

The command uploads the folder, waits for Mozilla's automatic validation (usually about a minute) and downloads the signed file to `.\signed`. Warnings do not block unlisted add-ons, only errors do. You also receive an e-mail when the version is approved.

### Optional: helper script

This asks for the keys instead of storing them in the file. It is a convenience example and was not tested on every setup.

```powershell
# Sign-FirefoxExtension.ps1
param(
    [string]$SourceDir    = ".\build",
    [string]$ArtifactsDir = ".\signed"
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

## 4. Install

1. In Firefox open `about:addons`.
2. Click the gear icon and choose **Install Add-on From File...**.
3. Select the signed `.xpi` from the `signed` folder. You can also drag it into the window.
4. If you had the extension loaded temporarily from `about:debugging`, remove it first (same ID).

## 5. Revoke the keys

Go back to <https://addons.mozilla.org/developers/addon/api/key/> and click **Revoke**. Generate new keys the next time you sign.

## Updating

Unlisted add-ons do not update themselves. For each new version: raise the version number, build, sign again (steps 2 and 3) and install the new `.xpi` over the old one. Your settings are kept as long as the ID is the same.

## Troubleshooting

| Message / symptom | Cause and fix |
| --- | --- |
| "This add-on could not be installed because it has not been verified" | The file is not signed. Sign it (step 3) or use one of the alternatives in the README. |
| Version already exists | That version number was already signed. Raise it in `package.json` and build again. |
| Installs as a second extension | The add-on ID is different. Check `browser_specific_settings.gecko.id` in `manifest.json`. |
| Authentication error from `web-ext` | Wrong or truncated JWT issuer/secret, or the keys were revoked. Generate new ones. |
| Validation errors | Read the message printed by `web-ext`. Warnings can be ignored for unlisted add-ons, errors cannot. |
