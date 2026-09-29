"""Session naming and stale state-dir cleanup, without a real Mutagen daemon."""

import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


SOURCE = (Path(__file__).resolve().parents[1] / "bin/docker").read_text()


def extract(name):
    body = SOURCE.split(f"\n{name}() {{", 1)[1].split("\n}\n", 1)[0]
    return f"{name}() {{{body}\n}}\n"


HELPERS = "".join(
    extract(name) for name in
    ("_read_file", "_pid_alive", "_mutagen_name", "_gc_stale_state_dirs")
)


def run(script, **env):
    return subprocess.run(
        ["zsh", "-f", "-c", HELPERS + script],
        env=dict(os.environ, **env), text=True, capture_output=True, timeout=10,
    )


class MutagenNameTests(unittest.TestCase):
    def test_names_satisfy_mutagen_rules(self):
        for slug in ("store_api-0123456789", "my app.v2-abc", "日本語-abc",
                     "x" * 100):
            with self.subTest(slug=slug):
                result = run("_mutagen_name " + shlex.quote(slug))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertRegex(result.stdout.strip(),
                                 re.compile(r"^[A-Za-z][A-Za-z0-9-]*$"))


class StaleStateDirTests(unittest.TestCase):
    def gc(self, home):
        # No mutagen daemon: `mutagen sync list` reports no sessions.
        return run("mutagen() { return 1; }\n_gc_stale_state_dirs", HOME=home)

    def test_empty_base_is_not_an_error(self):
        with tempfile.TemporaryDirectory() as home:
            (Path(home) / ".cache/docker-remote-wrapper").mkdir(parents=True)
            result = self.gc(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, "")

    def test_stale_dir_removed_and_locked_dir_kept(self):
        with tempfile.TemporaryDirectory() as home:
            base = Path(home) / ".cache/docker-remote-wrapper"
            (base / "stale-abc").mkdir(parents=True)
            (base / "busy-abc/.lock").mkdir(parents=True)
            (base / "not-a-dir").write_text("")
            result = self.gc(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((base / "stale-abc").exists())
            self.assertTrue((base / "busy-abc").exists())
            self.assertTrue((base / "not-a-dir").exists())


if __name__ == "__main__":
    unittest.main()
