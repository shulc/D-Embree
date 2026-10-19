#!/usr/bin/env python3
"""Exercise the owned patch's actual checkout bytes with Windows Git settings."""
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
        original = (ROOT / PATCH).read_bytes()
        self.assertGreater(original.count(b'\n'), 10, 'PATCH_POPULATION')
        self.assertNotIn(b'\r', original, 'PATCH_SOURCE_LF')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1',
                       GIT_CONFIG_GLOBAL=str(base / 'empty-config'))
            repository = base / 'repository'
            subprocess.run(['git', 'init', '-q', str(repository)], env=env, check=True)
            patch = repository / PATCH
            patch.parent.mkdir(parents=True)
            patch.write_bytes(original)
            attributes = ROOT / '.gitattributes'
            paths = [PATCH]
            if attributes.exists():
                (repository / '.gitattributes').write_bytes(attributes.read_bytes())
                paths.append('.gitattributes')
            subprocess.run(['git', '-C', str(repository), '-c', 'core.autocrlf=false',
                            'add', '--', *paths], env=env, check=True)
            subprocess.run(['git', '-C', str(repository), '-c', 'user.name=Fixture',
                            '-c', 'user.email=fixture@example.invalid',
                            'commit', '-qm', 'checkout fixture'], env=env, check=True)
            for setting in ('false', 'true', 'input'):
                with self.subTest(autocrlf=setting):
                    clone = base / setting
                    subprocess.run(['git', '-c', 'core.autocrlf=' + setting,
                                    'clone', '-q', '--no-local', str(repository), str(clone)],
                                   env=env, check=True)
                    self.assertEqual((clone / PATCH).read_bytes(), original,
                                     'PATCH_CHECKOUT_EXACT_BYTES_' + setting)


if __name__ == '__main__':
    unittest.main()
