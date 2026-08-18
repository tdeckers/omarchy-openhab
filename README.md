# OpenHAB for Omarchy

Bar widget for [Omarchy](https://omarchy.org) that shows the first selected
[OpenHAB](https://www.openhab.org) item. Click the pill to see the rest
(up to 10). Right-click or **Setup** configures the server and picks items.

Plugin id: `tdeckers.openhab`

## Install

```bash
omarchy plugin add https://github.com/tdeckers/omarchy-openhab.git --enable
```

Place it on the bar if needed:

```bash
omarchy bar move tdeckers.openhab --section right
```

## Setup

1. Left-click **OH** on the bar, then **Setup** (or right-click the pill).
2. Paste the OpenHAB URL (`http://openhab.local:8080` or `https://…`).
   If a reverse proxy sits in front, use that public URL.
3. Paste credentials:
   - `username:password` when the server uses HTTP Basic (common behind a proxy)
   - or an API token from OpenHAB → Profile → Security (starts with `oh.`)
4. **Save**, then **Reload items**.
5. Search the list and click rows to select (●). The first selected item is the bar label.

The secret is stored with `secret-tool` when a keyring is available; otherwise
it is written to `~/.config/omarchy/tdeckers.openhab.json` (mode 0600). Prefer
HTTPS.

Selected item names and the URL are stored in that same config file. It is
outside the plugin checkout and is never committed.

## Use

- Left-click the bar: status panel
- Right-click the bar: settings
- Escape closes the panel

States refresh every 15 seconds by default:

```bash
omarchy bar set tdeckers.openhab refreshIntervalSec 30
```

## Remove

```bash
omarchy plugin remove tdeckers.openhab
```

## Develop

```bash
git clone https://github.com/tdeckers/omarchy-openhab.git ~/git/omarchy-openhab
ln -sfn ~/git/omarchy-openhab ~/.config/omarchy/plugins/tdeckers.openhab
omarchy plugin validate ~/git/omarchy-openhab
omarchy plugin enable tdeckers.openhab --section right
```

```bash
python3 -m py_compile bin/openhab-api
python3 tests/test_openhab_api.py
```

Saves under the plugin folder hot-reload in `omarchy-shell`.

## License

MIT. Not affiliated with the OpenHAB project or Omarchy.
