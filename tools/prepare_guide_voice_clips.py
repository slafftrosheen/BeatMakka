"""Cut local companion guidance takes into cues at measured phrase pauses; no API calls."""
from pathlib import Path
import json,hashlib,subprocess,re,wave
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/production/needle-quay/guide-voices'
OUT=BASE/'clips';OUT.mkdir(exist_ok=True)
submission=json.loads((BASE/'submission.json').read_text(encoding='utf-8'))
records=[];catalog={}
for run in submission['runs']:
 speaker=run['speaker']
 for i,result in enumerate(run['results'],1):
  source=BASE/'source'/f'{speaker}-take{i}.mp3'
  records.append({'file':source.relative_to(ROOT).as_posix(),'generationId':next(iter(result['credit_costs'])),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'kind':'original'})
 source=BASE/'source'/f'{speaker}-take4.mp3'
 duration=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1',str(source)],text=True))
 r=subprocess.run(['ffmpeg','-hide_banner','-i',str(source),'-af','silencedetect=noise=-38dB:d=0.65','-f','null','-'],capture_output=True,text=True,check=True)
 starts=[float(x) for x in re.findall(r'silence_start: ([0-9.]+)',r.stderr)]
 ends=[float(x) for x in re.findall(r'silence_end: ([0-9.]+)',r.stderr)]
 gaps=[(a,b) for a,b in zip(starts,ends) if a>0.2 and b<duration-0.2]
 if len(gaps)!=len(submission['lines'])-1: raise ValueError('Review phrase cuts before preparing clips')
 for i,(cue,words) in enumerate(submission['lines'].items()):
  start=max(0,gaps[i-1][1]-0.08) if i else 0
  end=min(duration,gaps[i][0]+0.12) if i<len(gaps) else duration
  key=speaker+'_'+cue;target=OUT/(key+'.wav')
  subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-ss',str(start),'-i',str(source),'-t',str(end-start),'-af','loudnorm=I=-19:TP=-2:LRA=7,afade=t=in:d=0.005','-ac','1','-ar','44100','-c:a','pcm_s16le',str(target)],check=True)
  with wave.open(str(target)) as w: seconds=w.getnframes()/w.getframerate()
  catalog[key]={'file':target.name,'text':words,'duration':round(seconds,4)}
  records.append({'kind':'runtime-clip','file':target.relative_to(ROOT).as_posix(),'source':source.relative_to(ROOT).as_posix(),'start':start,'end':end,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
(ROOT/'src/shared/QuayGuideVoiceClips.luau').write_text('-- Generated local Studio companion guidance.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(catalog,separators=(',',':'))+']=])\n',encoding='utf-8')
(BASE/'provenance.json').write_text(json.dumps({'provider':'ElevenLabs','model':'eleven_v4','selection':'Take 4 of each speaker; 19 measured phrase pauses separate 20 authored lines.','processing':'Mono PCM16 44.1kHz; loudnorm target -19 LUFS, -2dB TP; 80ms lead,120ms tail.','runtimeVerified':False,'robloxUploads':0,'records':records},indent=2),encoding='utf-8')
print('Prepared',len(catalog),'guide clips; longest',max(x['duration'] for x in catalog.values()))
