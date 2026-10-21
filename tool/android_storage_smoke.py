"""Check the installed Android app's real storage startup path. No data is cleared."""
import os
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

adb = os.environ.get('ADB_PATH') or shutil.which('adb') or str(
    Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe')
serial = os.environ.get('ANDROID_SERIAL', 'emulator-5554')


def run(*args):
    return subprocess.check_output([adb, '-s', serial, *args], text=True, timeout=45)


if __name__ == '__main__':
    run('shell', 'am', 'force-stop', 'com.example.wafir')
    run('shell', 'am', 'start', '-W', '-n', 'com.example.wafir/.MainActivity')
    for attempt in range(5):
        run('shell', 'uiautomator', 'dump', '/sdcard/wafir-smoke.xml')
        root = ET.fromstring(run('exec-out', 'cat', '/sdcard/wafir-smoke.xml'))
        labels = '\n'.join(n.get('text', '') + n.get('content-desc', '') for n in root.iter('node'))
        assert 'Could not load your budget' not in labels, 'FAIL: Android storage startup error'
        if 'Start my budget' in labels or 'Budget settings' in labels:
            break
    else:
        raise AssertionError('FAIL: Budget screen did not load')
    print('PASS: Android storage loaded and the budget screen is visible')
