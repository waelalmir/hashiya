import pathlib
import re

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
if m.exists():
    s = m.read_text(encoding='utf-8')
    if 'RECORD_AUDIO' not in s:
        perms = ('    <uses-permission android:name="android.permission.INTERNET"/>\n'
                 '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n')
        s = s.replace('<application', perms + '    <application', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="حاشية"', s, count=1)
    m.write_text(s, encoding='utf-8')
    print('manifest patched')
else:
    print('WARNING: AndroidManifest.xml not found, skipping')

for g in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    p = pathlib.Path(g)
    if p.exists():
        t = p.read_text(encoding='utf-8')
        t = t.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
        t = t.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 24')
        p.write_text(t, encoding='utf-8')
        print('patched', g)
print('android patch done')
