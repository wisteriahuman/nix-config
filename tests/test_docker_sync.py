"""Verify environment-file propagation using an isolated local Mutagen daemon."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


SOURCE = (Path(__file__).resolve().parents[1] / "bin/docker").read_text()
SYNC_HELPERS = SOURCE.split("typeset -ga _MUTAGEN_IGNORE", 1)[1]
SYNC_HELPERS = "typeset -ga _MUTAGEN_IGNORE" + SYNC_HELPERS.split(
    "\n_mutagen_session_count()", 1
)[0]


@unittest.skipUnless(shutil.which("mutagen"), "Mutagen is not installed")
class EnvironmentSyncTests(unittest.TestCase):
    def setUp(self):
        # Keep the IPC socket path short on macOS. Never use the user's daemon.
        self.scratch = tempfile.TemporaryDirectory(prefix="env-sync-", dir="/tmp")
        self.root = Path(self.scratch.name)
        self.env = dict(os.environ, MUTAGEN_DATA_DIRECTORY=str(self.root / "data"))
        self.alpha = self.root / "alpha"
        self.beta = self.root / "beta"
        self.alpha.mkdir()
        self.beta.mkdir()
        self.addCleanup(self.scratch.cleanup)
        self.addCleanup(self.stop_daemon)

    def stop_daemon(self):
        subprocess.run(
            ["mutagen", "daemon", "stop"], env=self.env,
            capture_output=True, timeout=15, check=True,
        )

    def sync(self):
        # Ignore any machine-specific Mutagen global configuration in tests.
        helpers = SYNC_HELPERS.replace(
            "command mutagen sync create ",
            "command mutagen sync create --no-global-configuration ",
        )
        script = helpers + "\n_mutagen_ensure " + shlex.join(
            ["env-test", str(self.alpha), str(self.beta), str(self.alpha)]
        )
        result = subprocess.run(
            ["zsh", "-f", "-c", script], env=self.env,
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        subprocess.run(
            ["mutagen", "sync", "flush", "env-test"], env=self.env,
            capture_output=True, timeout=30, check=True,
        )

    def test_environment_files_sync_both_ways_and_vcs_is_ignored(self):
        app = self.alpha / "app"
        app.mkdir()
        names = [".env", ".env.testing", ".env.local.sample"]
        for name in names:
            (app / name).write_text("DUMMY_SETTING=local\n")
        (self.alpha / ".git").mkdir()
        (self.alpha / ".git" / "config").write_text("dummy-vcs-data\n")
        self.sync()
        for name in names:
            self.assertEqual((self.beta / "app" / name).read_text(), "DUMMY_SETTING=local\n")
        self.assertFalse((self.beta / ".git").exists())
        (self.beta / "app" / ".env").write_text("DUMMY_SETTING=remote\n")
        self.sync()
        self.assertEqual((app / ".env").read_text(), "DUMMY_SETTING=remote\n")

    def test_explicit_environment_ignore_is_respected(self):
        (self.alpha / ".env").write_text("DUMMY_SETTING=local\n")
        (self.alpha / ".env.production").write_text("DUMMY_SETTING=excluded\n")
        (self.alpha / ".dockerremoteignore").write_text("# Explicit exclusion\n\n.env.production\n")
        self.sync()
        self.assertTrue((self.beta / ".env").exists())
        self.assertFalse((self.beta / ".env.production").exists())


if __name__ == "__main__":
    unittest.main()
