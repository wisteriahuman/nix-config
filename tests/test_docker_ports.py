"""Verify forwarding selection without opening sockets or using SSH/Docker."""
import json
import os
import tempfile
from pathlib import Path
import shlex
import subprocess
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / 'bin/docker').read_text()
HELPER = '_compose_tunnel_specs() {' + SOURCE.split('_compose_tunnel_specs() {', 1)[1].split('\n_ensure_session()', 1)[0]

class TunnelSpecsTests(unittest.TestCase):
    def specs(self, ports, bindings=None):
        return subprocess.run(['zsh', '-fc', HELPER + '\n_compose_tunnel_specs ' + shlex.quote(json.dumps(bindings or {}))],
            input=json.dumps({'services': {'web': {'ports': ports}}}), text=True, capture_output=True)

    def test_unspecified_stays_loopback(self):
        result = self.specs([{'published': '9190'}, {'published': '3306'}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ['127.0.0.1:3306:127.0.0.1:3306', '127.0.0.1:9190:127.0.0.1:9190'])

    def test_only_selected_port_is_exposed(self):
        result = self.specs([{'published': '9190'}, {'published': '3306'}], {'9190': '0.0.0.0'})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ['0.0.0.0:9190:127.0.0.1:9190', '127.0.0.1:3306:127.0.0.1:3306'])

    def test_tailscale_address(self):
        result = self.specs([{'published': 9190}], {'9190': '100.64.1.2'})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), '100.64.1.2:9190:127.0.0.1:9190')

    def test_explicit_compose_addresses_are_preserved(self):
        result = self.specs([{'published': '9190', 'host_ip': '0.0.0.0'}, {'published': '3306', 'host_ip': '127.0.0.2'}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('0.0.0.0:9190:127.0.0.1:9190', result.stdout)
        self.assertIn('127.0.0.2:3306:127.0.0.2:3306', result.stdout)

    def test_loopback_cannot_be_widened(self):
        for ip in ['127.0.0.1', '127.0.0.2', '::1']:
            result = self.specs([{'published': '3306', 'host_ip': ip}], {'3306': '0.0.0.0'})
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('cannot widen', result.stderr)

    def test_ipv6_format_and_destination(self):
        result = self.specs([{'published': '9190', 'host_ip': '::'}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), '[::]:9190:[::1]:9190')

    def test_invalid_mapping_and_missing_ports_fail(self):
        for bindings in [{'9190': '-g; touch /tmp/UNEXPECTED'}, {'9191': '0.0.0.0'}, ['invalid']]:
            result = self.specs([{'published': '9190'}], bindings)
            self.assertNotEqual(result.returncode, 0)

    def test_udp_is_not_misrepresented_as_tcp(self):
        result = self.specs([{'published': '53', 'protocol': 'udp'}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '')
        self.assertNotEqual(self.specs([{'published': '53', 'protocol': 'udp'}], {'53': '0.0.0.0'}).returncode, 0)

    def test_duplicate_bindings_are_deduplicated(self):
        result = self.specs([{'published': '9190'}, {'published': '9190'}])
        self.assertEqual(len(result.stdout.splitlines()), 1)

    def test_empty_ports_and_ranges(self):
        self.assertEqual(self.specs([]).stdout, '')
        self.assertNotEqual(self.specs([{'published': '9190-9195'}]).returncode, 0)

ENSURE = '_ensure_session() {' + SOURCE.split('_ensure_session() {', 1)[1].split('\n_teardown_session()', 1)[0]

class TunnelLifecycleTests(unittest.TestCase):
    def session(self, bindings, previous, config_failure=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / '.dockerremoteports').write_text(json.dumps(bindings))
            (root / 'tunnel.pid').write_text('42')
            (root / 'tunnel.ports').write_text(previous)
            env = dict(os.environ, CASE_DIR=directory, CONFIG_FAILURE='1' if config_failure else '0')
            mocks = r'''
_lock_acquire() { return 0; }
_lock_release() { print -r -- unlock >> "$CASE_DIR/trace"; }
_remote_sync_path() { print -r -- "/tmp/remote project"; }
_mutagen_name() { print -r -- test-session; }
_mutagen_ensure() { return 0; }
_read_file() { cat "$1"; }
_pid_alive() { [[ "$1" == 42 ]]; }
_kill_pid() { print -r -- "kill:$1" >> "$CASE_DIR/trace"; }
ssh() {
  if [[ "$1" == -N ]]; then
    print -r -- "$*" >> "$CASE_DIR/trace"
  else
    (( CONFIG_FAILURE == 0 )) || return 255
    print -r -- '{"services":{"web":{"ports":[{"published":"9190"}]}}}'
  fi
}
_DOCKER_REMOTE_HOST=test-host
'''
            script = mocks + HELPER + ENSURE + '\n_ensure_session "$CASE_DIR" test "$CASE_DIR"\nrc=$?\nwait\nexit $rc'
            result = subprocess.run(['zsh', '-fc', script], env=env, text=True, capture_output=True)
            return result, (root / 'trace').read_text(), (root / 'tunnel.ports').read_text()

    def test_address_change_restarts_tunnel_with_full_spec(self):
        result, trace, key = self.session({'9190':'0.0.0.0'}, '127.0.0.1:9190:127.0.0.1:9190')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('kill:42', trace)
        self.assertIn('-o ExitOnForwardFailure=yes -L 0.0.0.0:9190:127.0.0.1:9190', trace)
        self.assertEqual(key.strip(), '0.0.0.0:9190:127.0.0.1:9190')

    def test_unchanged_config_keeps_existing_tunnel(self):
        result, trace, _ = self.session({}, '127.0.0.1:9190:127.0.0.1:9190')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(trace.strip(), 'unlock')

    def test_invalid_config_or_ssh_failure_keeps_previous_tunnel(self):
        for bindings, failure in [({'9999':'0.0.0.0'}, False), ({}, True)]:
            result, trace, key = self.session(bindings, 'previous', failure)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(key, 'previous')
            self.assertEqual(trace.strip(), 'unlock')

if __name__ == '__main__':
    unittest.main()
