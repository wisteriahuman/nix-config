"""bin/docker: `docker compose` の引数から compose ファイルの指定を拾う部分。"""

import subprocess
import unittest
from pathlib import Path


SOURCE = (Path(__file__).resolve().parents[1] / "bin/docker").read_text()


def extract(name):
    body = SOURCE.split(f"\n{name}() {{", 1)[1].split("\n}\n", 1)[0]
    return f"{name}() {{{body}\n}}\n"


def extract_all(*names):
    return "".join(extract(n) for n in names)


def files(*args):
    quoted = " ".join("'" + a.replace("'", "'\\''") + "'" for a in args)
    result = subprocess.run(
        ["zsh", "-f", "-c", extract_all("_compose_global_count", "_compose_global_files") + f"_compose_global_files {quoted}"],
        text=True, capture_output=True, timeout=10,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return result.stdout.splitlines()


def count(*args):
    quoted = " ".join("'" + a.replace("'", "'\\''") + "'" for a in args)
    result = subprocess.run(
        ["zsh", "-f", "-c", extract("_compose_global_count") + f"_compose_global_count {quoted}"],
        text=True, capture_output=True, timeout=10,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return int(result.stdout.strip())


class ComposeGlobalCountTests(unittest.TestCase):
    def test_subcommand_first(self):
        self.assertEqual(count("up", "-d"), 0)

    def test_file_before_up_is_global(self):
        # 以前は -f をサブコマンドと見て、up を tmux の経路に通さなかった
        self.assertEqual(count("-f", "compose.dev.yaml", "up", "--build", "server"), 2)

    def test_mixed_global_options(self):
        self.assertEqual(count("--file=a.yaml", "-p", "proj", "--dry-run", "down"), 4)

    def test_options_after_the_subcommand_are_not_counted(self):
        self.assertEqual(count("-f", "c.yaml", "run", "--rm", "svc", "tool", "-f", "x"), 2)


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
