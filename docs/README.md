# My Home

iOS client for the MyHomeHub. Control your devices, scenarios, and rooms from your iPhone.

![My Home Banner](assets/banner.png)

## Before you start

- iPhone running **iOS 18.6** or newer
- A free **Apple ID** (a dedicated one for sideloading is recommended)
- An **always-on computer** to run AltServer. This guide uses a Linux home server so refresh happens without keeping a laptop on; a Mac or PC works too, but must stay awake on the same Wi-Fi.

## Install AltStore

The app is distributed through [AltStore](https://altstore.io) — a companion app, **AltServer**, signs it with your own Apple ID and refreshes it before it expires. Nothing you install this way leaves your phone.

### On the server:

1. Install the AltServer:

```bash
sudo scripts/install_altserver.sh
```

2. Connect the phone by USB for the first pairing, then run the pairing script:

```bash
scripts/install_altstore.sh -a <apple-id> -p "<password>"
```

> **First-pairing tips:** use a proper **data** cable plugged **straight into the server** (no hubs or docks), and keep the phone **unlocked** — tap **Trust This Computer** and enter your passcode when prompted. Confirm it's seen with `docker exec altserver idevice_id -l` (should print the UDID) before running the script. A charge-only or flaky cable is the usual reason a phone won't pair.

3. Once AltStore is installed, open it on your phone and sign in under **Settings** with your Apple ID (you'll get a 2FA prompt).

## Install My Home

In AltStore, tap **Sources → +** and paste this URL:

```
https://ilyamatsuev.github.io/MyHomeApp/apps.json
```

Add the **My Home** source and install the app.

## Keep the app refreshed

Apps signed with a free Apple ID expire every **7 days**. With the `altserver` container left running on the server, AltStore renews them automatically over Wi-Fi:

1. Keep the `altserver` container running and the phone on the same Wi-Fi/subnet as the server.
2. iOS **Settings → General → Background App Refresh** — turn it on globally and for AltStore.

> If a refresh fails, open AltStore → **My Apps** and pull down to refresh manually.

## Updates

New versions show up automatically in **My Apps** — pull to refresh and tap **Update**.

---

Source code: [github.com/IlyaMatsuev/MyHomeApp](https://github.com/IlyaMatsuev/MyHomeApp)

Licensed under [PolyForm Noncommercial](https://github.com/IlyaMatsuev/MyHomeApp/blob/main/LICENSE).
