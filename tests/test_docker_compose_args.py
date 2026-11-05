"""bin/docker: `docker compose` の引数から compose ファイルの指定を拾う部分。"""

import subprocess
import unittest
from pathlib import Path


SOURCE = (Path(__file__).resolve().parents[1] / "bin/docker").read_text()


def extract(name):
    body = SOURCE.split(f"\n{name}() {{", 1)[1].split("\n}\n", 1)[0]
    return f"{name}() {{{body}\n}}\n"


def files(*args):
    quoted = " ".join("'" + a.replace("'", "'\\''") + "'" for a in args)
    result = subprocess.run(
        ["zsh", "-f", "-c", extract("_compose_global_files") + f"_compose_global_files {quoted}"],
        text=True, capture_output=True, timeout=10,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return result.stdout.splitlines()


class ComposeGlobalFilesTests(unittest.TestCase):
    def test_file_after_the_subcommand_belongs_to_the_container(self):
        # devhub-backend の make db-apply（ridgepole -f Schemafile）で踏んだ形
        self.assertEqual(
            files("-f", "compose.dev.yaml", "run", "--rm", "ridgepole", "ridgepole", "--apply", "-f", "Schemafile"),
            ["compose.dev.yaml"])

    def test_only_container_args_mean_no_compose_file(self):
        self.assertEqual(files("run", "--rm", "app", "tool", "-f", "x.yaml"), [])

    def test_equals_form_and_multiple_files(self):
        self.assertEqual(files("--file=a.yaml", "-f", "b.yaml", "up", "-d"), ["a.yaml", "b.yaml"])

    def test_options_with_values_are_skipped(self):
        self.assertEqual(files("-p", "proj", "--env-file", ".env.dev", "-f", "c.yaml", "up"), ["c.yaml"])

    def test_flags_without_values_do_not_end_the_scan(self):
        self.assertEqual(files("--dry-run", "-f", "d.yaml", "down"), ["d.yaml"])


if __name__ == "__main__":
    unittest.main()
