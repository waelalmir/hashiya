import pathlib
import re

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = m.read_text(encoding='utf-8')
if 'RECORD_AUDIO' not in s:
    perms = ('    <uses-permission android:name="android.permission.INTERNET"/>\n'
             '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n')
    s = s.replace('<application', perms + '    <application', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="حاشية"', s, count=1)
m.write_text(s, encoding='utf-8')

for g in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    p = pathlib.Path(g)
    if p.exists():
        t = p.read_text(encoding='utf-8')
        t = t.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24').replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 24')
        p.write_text(t, encoding='utf-8')
print('android patched')
