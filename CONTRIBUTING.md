# Contributing

Install for end users is in the [README](README.md). This file is the local
checkout used while changing the plugin.

Symlink a clone into the Omarchy user plugin directory (the folder name must
match the plugin id):

```
ln -sfn /path/to/omarchy-openhab ~/.config/omarchy/plugins/tdeckers.openhab
omarchy plugin validate ~/.config/omarchy/plugins/tdeckers.openhab
omarchy plugin enable tdeckers.openhab --section right
```

Saves under that folder hot-reload in `omarchy-shell`.

```
python3 -m py_compile bin/openhab-api
python3 tests/test_openhab_api.py
```
