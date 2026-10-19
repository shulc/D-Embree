#!/usr/bin/env python3
"""Exercise tracked source bytes and the patch with Windows Git settings."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PATCH = 'native/patches/embree4.4.1-user-closed-interval.patch'


class PatchCheckout(unittest.TestCase):
    def test_ci(self):
        workflow = (ROOT / '.github/workflows/ci.yml').read_text()
        self.assertIn('python -m unittest discover -s tests/packaging', workflow,
                      'PATCH_CHECKOUT_CI_WIRING')

    def test_checkout(self):
        paths = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z'])
        paths = [name for name in paths.decode().split('\0') if name]
        self.assertGreaterEqual(len(paths), 47, 'TRACKED_SOURCE_POPULATION')
        original = {name: (ROOT / name).read_bytes() for name in paths}
        self.assertGreater(original[PATCH].count(b'\n'), 10, 'PATCH_POPULATION')
        self.assertNotIn(b'\r', original[PATCH], 'PATCH_SOURCE_LF')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1',
                       GIT_CONFIG_GLOBAL=str(base / 'empty-config'))
            repository = base / 'repository'
            subprocess.run(['git', 'init', '-q', str(repository)], env=env, check=True)
            for name, raw in original.items():
                path = repository / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(raw)
            subprocess.run(['git', '-C', str(repository), '-c', 'core.autocrlf=false',
                            'add', '--', *paths], env=env, check=True)
            subprocess.run(['git', '-C', str(repository), '-c', 'user.name=Fixture',
                            '-c', 'user.email=fixture@example.invalid',
                            'commit', '-qm', 'checkout fixture'], env=env, check=True)
            for name, raw in original.items():
                blob = subprocess.check_output(['git', '-C', str(repository),
                                                'show', 'HEAD:' + name], env=env)
                self.assertEqual(raw, blob, 'TRACKED_GIT_BLOB_BYTES_' + name)
            for setting in ('false', 'true', 'input'):
                with self.subTest(autocrlf=setting):
                    clone = base / setting
                    subprocess.run(['git', '-c', 'core.autocrlf=' + setting,
                                    'clone', '-q', '--no-local', str(repository), str(clone)],
                                   env=env, check=True)
                    self.assertEqual((clone / PATCH).read_bytes(), original[PATCH],
                                     'PATCH_CHECKOUT_EXACT_BYTES_' + setting)
                    for name, raw in original.items():
                        self.assertEqual((clone / name).read_bytes(), raw,
                                         'TRACKED_CHECKOUT_EXACT_BYTES_' + setting +
                                         ' PATH=' + name)


if __name__ == '__main__':
    unittest.main()
