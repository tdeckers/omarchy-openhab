#!/usr/bin/env python3
import importlib.util
import json
import sys
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "bin" / "openhab-api"


def load_api():
    loader = SourceFileLoader("openhab_api", str(API))
    spec = importlib.util.spec_from_loader("openhab_api", loader)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {API}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.mod = load_api()
        self.tmp = tempfile.TemporaryDirectory()
        self.cfg = Path(self.tmp.name) / "tdeckers.openhab.json"
        self.mod.CONFIG_PATH = str(self.cfg)

    def tearDown(self):
        self.tmp.cleanup()

    def test_normalize_url_strips_rest_suffix(self):
        self.assertEqual(self.mod.normalize_url("https://oh.example/rest/"), "https://oh.example")

    def test_normalize_secret_strips_bearer_prefix(self):
        self.assertEqual(self.mod.normalize_secret(' Bearer abc '), "abc")

    def test_userpass_prefers_basic_auth(self):
        names = [name for name, _ in self.mod.auth_attempts("admin:secret")]
        self.assertEqual(names[0], "basic")

    def test_api_token_starts_with_bearer(self):
        names = [name for name, _ in self.mod.auth_attempts("oh.user.token.abc")]
        self.assertEqual(names[0], "bearer")

    def test_toggle_and_cap_selected_items(self):
        cfg = {"url": "https://oh.example", "items": [], "token": ""}
        self.mod.save_config(cfg)
        self.mod.secret_lookup = lambda: ""
        payload = {"url": "https://oh.example", "items": [f"i{n}" for n in range(15)]}
        with mock.patch.object(sys, "stdin", mock.Mock(read=lambda: json.dumps(payload))):
            with mock.patch.object(self.mod, "emit"):
                self.mod.cmd_config_set()
        saved = json.loads(self.cfg.read_text())
        self.assertEqual(len(saved["items"]), 10)
        self.assertEqual(saved["items"][0], "i0")

    def test_save_config_creates_private_file(self):
        self.mod.save_config({"url": "https://oh.example", "items": [], "token": "secret-value"})
        mode = self.cfg.stat().st_mode & 0o777
        self.assertEqual(mode, 0o600)

    def test_config_get_never_emits_token(self):
        self.mod.save_config({"url": "https://oh.example", "items": ["Lamp"], "token": "secret-value"})
        with mock.patch.object(self.mod, "secret_lookup", return_value=""):
            captured = {}

            def fake_emit(payload):
                captured.update(payload)

            with mock.patch.object(self.mod, "emit", fake_emit):
                self.mod.cmd_config_get()
        self.assertTrue(captured["ok"])
        self.assertTrue(captured["hasToken"])
        self.assertNotIn("token", captured)
        self.assertNotIn("secret-value", json.dumps(captured))


if __name__ == "__main__":
    unittest.main()
