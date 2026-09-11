"""Exercise the actual up handler with a local shell standing in for SSH."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "bin/docker").read_text()
UP_HANDLER = SOURCE.split("_compose_up() {", 1)[1].split("\n# `down`:", 1)[0]
UP_HANDLER = "_compose_up() {" + UP_HANDLER


class ComposeUpTests(unittest.TestCase):
    def run_up(self, args, *, compose_exit=0, ssh_exit=0, foreground=False):
        with tempfile.TemporaryDirectory() as directory:
            scratch = Path(directory)
            remote = scratch / "remote's project $(touch UNEXPECTED)"
            remote.mkdir()
            fake_bin = scratch / "bin"
            fake_bin.mkdir()
            docker = fake_bin / "docker"
            docker.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, pathlib, sys, time\n"
                "time.sleep(0.05)\n"
                "pathlib.Path(os.environ['CAPTURE']).write_text(\n"
                "    json.dumps({'args': sys.argv[1:], 'cwd': os.getcwd()}))\n"
                "print('Compose startup finished', flush=True)\n"
                "print('Compose diagnostic', file=sys.stderr, flush=True)\n"
                "sys.exit(int(os.environ['COMPOSE_EXIT']))\n"
            )
            docker.chmod(0o755)
            env = dict(
                os.environ,
                PATH=str(fake_bin) + os.pathsep + os.environ["PATH"],
                CAPTURE=str(scratch / "args.json"),
                TRACE=str(scratch / "trace"),
                COMPOSE_EXIT=str(compose_exit),
                SSH_EXIT=str(ssh_exit),
                FOREGROUND="1" if foreground else "0",
            )
            script = r'''
_DOCKER_REMOTE_HOST=wisteria@surface
_mutagen_name() { print -r -- "dr-$1"; }
_mutagen_flush() {
  print -r -- "flush:$1" >> "$TRACE"
  # Post-run sync must not replace Compose's exit status.
  return 19
}
ssh() {
  print -r -- "ssh:$*" >> "$TRACE"
  if [[ "$FOREGROUND" == 1 ]]; then
    if [[ "$*" == *"has-session"* ]]; then
      return 1
    elif [[ "$*" == *"new-session"* ]]; then
      return "$SSH_EXIT"
    elif [[ "$*" == *"attach -t"* ]]; then
      print -r -- attached
      return 0
    fi
    return 98
  fi
  [[ "$1" == -T && "$2" == wisteria@surface && $# == 3 ]] || return 97
  [[ "$3" != *tmux* ]] || return 96
  (( SSH_EXIT == 0 )) || return "$SSH_EXIT"
  /bin/sh -c "$3"
}
'''
            invocation = [str(remote), "existing-tmux", "project", *args]
            script += UP_HANDLER + "\n_compose_up " + shlex.join(invocation)
            result = subprocess.run(
                ["zsh", "-f", "-c", script], cwd=scratch, env=env,
                text=True, capture_output=True, timeout=10,
            )
            capture = scratch / "args.json"
            recorded = json.loads(capture.read_text()) if capture.exists() else None
            trace = (scratch / "trace").read_text()
            self.assertFalse((scratch / "UNEXPECTED").exists())
            self.assertFalse((remote / "UNEXPECTED").exists())
            if recorded:
                self.assertEqual(Path(recorded["cwd"]).resolve(), remote.resolve())
            return result, recorded, trace

    def test_detached_success_waits_and_preserves_arguments(self):
        args = ["-d", "--build", "--scale", "web=2", "web's $(touch UNEXPECTED)"]
        result, recorded, trace = self.run_up(args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(recorded["args"], ["compose", "up", *args])
        self.assertIn("Compose startup finished", result.stdout)
        self.assertIn("Compose diagnostic", result.stderr)
        self.assertEqual(trace.count("flush:dr-project"), 2)
        self.assertNotIn("tmux", trace)

    def test_compose_failure_reaches_caller(self):
        result, recorded, _ = self.run_up(["--detach"], compose_exit=7)
        self.assertEqual(result.returncode, 7)
        self.assertIsNotNone(recorded)
        self.assertIn("Compose diagnostic", result.stderr)
        self.assertNotIn("containers starting", result.stderr)

    def test_wait_and_boolean_forms_use_detached_path(self):
        for args in (["--wait", "--wait-timeout", "120"],
                     ["--detach=true"], ["-d=true"],
                     ["--detach=false", "--wait=true"]):
            with self.subTest(args=args):
                result, recorded, _ = self.run_up(args)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(recorded["args"], ["compose", "up", *args])

    def test_health_wait_failure_reaches_caller(self):
        result, _, _ = self.run_up(["--wait"], compose_exit=1)
        self.assertEqual(result.returncode, 1)

    def test_ssh_failure_is_not_reported_as_success(self):
        result, recorded, _ = self.run_up(["-d"], ssh_exit=255)
        self.assertEqual(result.returncode, 255)
        self.assertIsNone(recorded)

    def test_foreground_still_attaches(self):
        for args in ([], ["--detach=false"], ["--wait=false"]):
            with self.subTest(args=args):
                result, recorded, trace = self.run_up(args, foreground=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIsNone(recorded)
                self.assertIn("attached", result.stdout)
                self.assertIn("new-session", trace)

    def test_tmux_creation_failure_stops_before_attach(self):
        result, _, trace = self.run_up([], foreground=True, ssh_exit=23)
        self.assertEqual(result.returncode, 23)
        self.assertNotIn("attach -t", trace)


if __name__ == "__main__":
    unittest.main()
