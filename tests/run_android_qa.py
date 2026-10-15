"""Drive installed QA build through Android lifecycle; retain runtime evidence."""
import json, subprocess, time, re
from pathlib import Path
pkg='com.sergiomrge.dungeonsfires.qa.v050'
out=Path('/tmp/android-runtime');out.mkdir(exist_ok=True)
def adb(*args,check=True):
 return subprocess.run(['adb',*args],check=check,capture_output=True).stdout

def wait_stage(stage):
 deadline=time.monotonic()+90
 while time.monotonic()<deadline:
  raw=adb('shell','run-as',pkg,'cat','files/android_qa.json',check=False)
  try:
   result=json.loads(raw)
   if result.get('stage')==stage:return result
  except (ValueError,UnicodeError):pass
  time.sleep(1)
 raise RuntimeError('Android QA never reached '+stage)
try:
 adb('install','-r','/tmp/android-qa.apk')
 adb('logcat','-c')
 adb('shell','monkey','-p',pkg,'1')
 first=wait_stage('checkpoint');(out/'01_runtime.json').write_text(json.dumps(first,indent=2))
 assert all(first['checks'].values()),first
 (out/'01_gameplay.png').write_bytes(adb('exec-out','screencap','-p'))
 adb('shell','input','keyevent','KEYCODE_HOME')
 paused=wait_stage('paused');(out/'02_pause.json').write_text(json.dumps(paused,indent=2))
 assert all(paused['checks'].values()),paused
 adb('shell','am','force-stop',pkg)
 adb('shell','monkey','-p',pkg,'1')
 resumed=wait_stage('complete');(out/'03_resume.json').write_text(json.dumps(resumed,indent=2))
 assert all(resumed['checks'].values()),resumed
 time.sleep(1)
 (out/'03_resumed.png').write_bytes(adb('exec-out','screencap','-p'))
 print(json.dumps({'android_api':29,'runtime':first,'pause':paused['checks'],'restart':resumed['checks']}))
finally:
 log=adb('logcat','-d',check=False)
 (out/'logcat.txt').write_bytes(log)
 assert not re.search(rb'(SCRIPT ERROR|E godot\s*: ERROR:|FATAL EXCEPTION)',log), 'Godot/Android runtime error found in retained logcat'
