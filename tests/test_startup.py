"""Run scripts without their helper; no real server commands may execute."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which('bash') or (r'C:\Program Files\Git\bin\bash.exe' if os.name == 'nt' else None)


@unittest.skipUnless(BASH and Path(BASH).exists(), 'Bash is required')
class StartupTests(unittest.TestCase):
    def test_missing_helper_exits_before_operating(self):
        for script in ROOT.glob('*.sh'):
            if script.name == 'common.sh':
                continue
            with self.subTest(script=script.name), tempfile.TemporaryDirectory() as folder:
                fixture = Path(folder)
                (fixture/script.name).write_text(script.read_text(), newline='\n')
                # No external commands can mutate anything in this fixture.
                prelude = '''
dirname() { printf '.'; }
fail() { printf 'AFTER_HELPER\\n'; return 0; }
require_root() { printf 'AFTER_HELPER\\n'; }
validate_domain() { printf 'AFTER_HELPER\\n'; }
mv() { printf 'AFTER_HELPER\\n'; }
rm() { printf 'AFTER_HELPER\\n'; }
mkdir() { printf 'AFTER_HELPER\\n'; }
hostname() { return 1; }
mktemp() { return 1; }
reload_config() { return 1; }
export -f dirname fail require_root validate_domain mv rm mkdir hostname mktemp reload_config
source "$1"
'''
                result = subprocess.run([BASH, '-c', prelude, 'test', './'+script.name], cwd=fixture, capture_output=True, text=True, timeout=5)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('AFTER_HELPER', result.stdout)


if __name__ == '__main__':
    unittest.main()
