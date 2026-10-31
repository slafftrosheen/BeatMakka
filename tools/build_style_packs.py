"""Build ten compact key-coherent kits from the user's RAR collections.

Untouched selected source bytes, archive/member provenance and mono PCM16
derivatives are kept in the repo. No network, upload, playback or paid calls.
Requires existing Windows tar, ffmpeg, Pillow and NumPy. --verify is offline.
"""
import argparse
import hashlib
import json
import re
import subprocess
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/candidates/audio/style-starters-v1'
RATE = 44100
# Prefix, count, role. Generic archive drum hits remain honestly named drums.
STYLES = {
    'TripHop': ('Trip Hop', 'A minor', [45,48,52,55], [('DRUMSHOT',8,'drum'),('GUITSHOT',4,'guitar'),('KEYSHOT',4,'keys')]),
    'Dance': ('Dance', 'A minor', [45,48,52,55], [('KICK',2,'kick'),('SNARE',2,'snare'),('HIHAT',2,'hat'),('CLAP',2,'clap'),('BASSSHOT',2,'bass'),('KEYSHOT',4,'keys'),('FXSHOT',2,'fx')]),
    'Grunge': ('Grunge', 'D minor', [38,41,45,48], [('DRUMLOOP',4,'drum_cut'),('PERCLOOP',2,'percussion_cut'),('ELECGUIT',4,'guitar'),('ORGAN',4,'organ'),('STRING',2,'strings')]),
    'Hardtrance': ('Hard Trance', 'A minor', [45,48,52,55], [('KICK',2,'kick'),('SNARE',2,'snare'),('CLAP',1,'clap'),('PERCUSSN',3,'percussion'),('SNTHBASS',3,'bass'),('SYNTH',3,'synth'),('FX',2,'fx')]),
    'HipHop': ('Hip Hop', 'A minor', [45,48,52,55], [('DRUMSHOT',8,'drum'),('BASSSHOT',2,'bass'),('GUITSHOT',2,'guitar'),('KEYSHOT',2,'keys'),('FXSHOT',2,'fx')]),
    'Industrial': ('Industrial', 'A minor', [45,48,52,55], [('SNARE',4,'snare'),('TOM',2,'tom'),('FX',4,'fx'),('SYNTH',4,'synth'),('PERCLOOP',2,'percussion_cut')]),
    'Pop': ('Pop', 'D major', [38,42,45,49], [('PERCUSSN',6,'percussion'),('DRUMLOOP',2,'drum_cut'),('ELECBASS',2,'bass'),('ACSTGUIT',2,'guitar'),('PIANO',4,'piano')]),
    'Reggae': ('Reggae', 'A minor', [45,48,52,55], [('DRUMSHOT',6,'drum'),('PERCUSSN',2,'percussion'),('BASSSHOT',2,'bass'),('GUITSHOT',4,'guitar'),('KEYSHOT',2,'keys')]),
    'Techno': ('Techno', 'A minor', [45,48,52,55], [('KICK',2,'kick'),('SNARE',2,'snare'),('HIHAT',2,'hat'),('CLAP',2,'clap'),('BASSSHOT',2,'bass'),('KEYSHOT',4,'keys'),('FXSHOT',2,'fx')]),
    'Trance': ('Trance', 'A minor', [45,48,52,55], [('KICK',2,'kick'),('SNARE',2,'snare'),('CLAP',2,'clap'),('PERCUSSN',2,'percussion'),('SNTHBASS',2,'bass'),('SYNTH',4,'synth'),('FX',2,'fx')]),
}
TONAL = {'bass','guitar','keys','organ','strings','synth','piano','fx'}
NOTES = ['C','C#','D','Eb','E','F','F#','G','Ab','A','Bb','B']


def note_metadata(role, edits, ordinal):
    midi = edits.get('target_midi')
    if midi is None:
        return {'label':role.replace('_',' ').title()+f' {ordinal:02d}'}
    note = NOTES[midi%12]+str(midi//12-1)
    return {'note':note,'label':role.title()+' '+note}


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''): h.update(chunk)
    return h.hexdigest()


def run(args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def decode(path):
    raw = run(['ffmpeg','-v','error','-threads','1','-i',str(path),'-map','0:a:0','-ac','1','-ar',str(RATE),'-f','f32le','-'])
    data = np.frombuffer(raw, dtype='<f4').astype(np.float64)
    if len(data) == 0 or not np.isfinite(data).all(): raise ValueError('Invalid source audio: '+str(path))
    return data - np.mean(data)


def derive(data, role, midi):
    # Capture the first real onset; loop-derived pads are explicitly labelled cuts.
    threshold = max(np.max(np.abs(data)) * .025, .0001)
    active = np.flatnonzero(np.abs(data) > threshold)
    if len(active) == 0: raise ValueError('Silent source')
    start = max(0, int(active[0]) - 88)
    duration = .8 if role in TONAL else .45 if role.endswith('_cut') else 1.0
    signal = data[start:min(int(active[-1])+133, start+int(duration*RATE))].copy()
    edits = {'source_start_frame':start, 'source_end_frame':start+len(signal), 'method':'onset cut; no pitch applied'}
    if role in TONAL:
        # Preserve the source's relative harmonic color and decay, but project it
        # onto ONE note. This removes incompatible chord tones/modes rather than
        # assuming a filename's root letter guarantees harmonic compatibility.
        n = min(len(signal), 16384)
        spectrum = np.abs(np.fft.rfft(signal[:n] * np.hanning(n)))
        frequencies = np.fft.rfftfreq(n, 1/RATE)
        candidates = 440 * 2 ** ((np.arange(33,73) - 69) / 12)
        scores = [sum(np.interp(f*np.arange(1,9), frequencies, spectrum) / np.arange(1,9)) for f in candidates]
        source_f0 = float(candidates[int(np.argmax(scores))])
        amplitudes = np.interp(source_f0*np.arange(1,25), frequencies, spectrum)
        amplitudes[0] = max(amplitudes[0], np.max(amplitudes)*.35)
        amplitudes /= max(np.sum(amplitudes), 1e-9)
        hz = 440 * 2 ** ((midi - 69)/12)
        t = np.arange(len(signal))/RATE
        # Coarse source envelope retains distinct strikes/plucks/sustains.
        block = 441
        centers = np.arange(0,len(signal),block)
        env = np.array([np.sqrt(np.mean(signal[i:min(i+block,len(signal))]**2)) for i in centers])
        envelope = np.interp(np.arange(len(signal)),centers,env)
        envelope /= max(float(np.max(envelope)),1e-9)
        signal = sum(a*np.sin(2*np.pi*hz*(i+1)*t) for i,a in enumerate(amplitudes)) * envelope
        edits.update({'method':'source harmonic/envelope projection to one key-compatible note; not a raw pitch-shift', 'source_reference_hz':source_f0,'target_midi':midi,'target_hz':hz,'harmonic_amplitudes':amplitudes.tolist()})
    fade_in, fade_out = min(88,len(signal)//4), min(441,len(signal)//4)
    signal[:fade_in] *= np.linspace(0,1,fade_in)
    signal[-fade_out:] *= np.linspace(1,0,fade_out)
    peak = float(np.max(np.abs(signal)))
    rms = float(np.sqrt(np.mean(signal**2)))
    gain = min(10**(-9/20)/max(peak,1e-9), 10**(-24/20)/max(rms,1e-9), 4)
    signal *= gain
    edits.update({'fade_in_frames':fade_in,'fade_out_frames':fade_out,'gain_db':float(20*np.log10(gain))})
    return signal,edits


def save_wav(path, signal):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.rint(signal*32767).astype('<i2')
    with wave.open(str(path),'wb') as out:
        out.setparams((1,2,RATE,0,'NONE','not compressed'));out.writeframes(pcm.tobytes())


def build(music):
    if (ROOT/'data/active-content.json').exists():
        raise RuntimeError('Historical style samples are retired and cannot be regenerated.')
    if DEST.exists(): raise SystemExit('Pack destination exists; use --verify, never overwrite reviewed sources')
    packs = []
    for name,(label,key,notes,groups) in STYLES.items():
        archive = music/(name+'.rar')
        entries = run(['C:/Windows/System32/tar.exe','-tf',str(archive)]).decode('utf-8').splitlines()
        choices = []
        for prefix,count,role in groups:
            pool = sorted(p for p in entries if p.lower().endswith('.wav') and Path(p).name.startswith(prefix) and '(R)' not in p)
            if len(pool)<count: raise ValueError(f'{name}/{prefix}: need {count}, found {len(pool)}')
            for index in np.linspace(0,len(pool)-1,count,dtype=int):
                member = pool[index]
                sources = [member]
                if '(L)' in member:
                    right = member.replace('(L)','(R)')
                    if right not in entries: raise ValueError('Missing stereo mate: '+member)
                    sources.append(right)
                choices.append((sources,role))
        assert len(choices)==16
        members = list(dict.fromkeys(p for sources,_ in choices for p in sources))
        assert all(entries.count(p)==1 and not Path(p).is_absolute() and '..' not in Path(p).parts and '\\' not in p for p in members)
        extracted = ROOT/'work/style-pack-inputs'/name
        extracted.mkdir(parents=True, exist_ok=False)
        run(['C:/Windows/System32/tar.exe','-xf',str(archive),'-C',str(extracted),*members])
        pack_id = name.lower()
        pack = {'id':pack_id,'label':label,'key':key,'midi_notes':notes,'suggested_bpm':90 if name in ['TripHop','Grunge','HipHop','Pop','Reggae'] else 140,'archive':archive.name,'archive_sha256':digest(archive),'samples':[]}
        tonal_index = 0
        for pad,(members,role) in enumerate(choices,1):
            sample_id = f'style.{pack_id}.{pad:02d}'
            stem = f'{pad:02d}_{role}'
            sources, decoded = [], []
            for channel,member in enumerate(members):
                src = extracted/member
                assert src.is_file() and not src.is_symlink()
                target = DEST/pack_id/'sources'/(stem+('.left' if channel==0 else '.right' if len(members)>1 else '')+'.wav') if len(members)>1 else DEST/pack_id/'sources'/(stem+'.wav')
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(src.read_bytes())
                sources.append({'archive_member':member,'file':str(target.relative_to(ROOT)).replace('\\','/'),'sha256':digest(target)})
                decoded.append(decode(src))
            length = min(map(len,decoded))
            data = sum(s[:length] for s in decoded)/len(decoded)
            midi = notes[tonal_index%len(notes)] + (12 if role not in ['bass'] else 0)
            signal,edits = derive(data,role,midi)
            if role in TONAL: tonal_index+=1
            target = DEST/pack_id/'samples'/(stem+'.wav');save_wav(target,signal)
            pack['samples'].append({'id':sample_id,'pad':pad,'label':role.replace('_',' ').title()+f' {sum(s[1]==role for s in choices[:pad]):02d}','role':role,'sources':sources,'file':str(target.relative_to(ROOT)).replace('\\','/'),'sha256':digest(target),'frames':len(signal),'duration_seconds':len(signal)/RATE,'peak_dbfs':float(20*np.log10(max(np.max(np.abs(signal)),1e-9))),'rms_dbfs':float(20*np.log10(max(np.sqrt(np.mean(signal**2)),1e-9))),'edits':edits,'asset_id':None})
            pack['samples'][-1].update(note_metadata(role,edits,sum(s[1]==role for s in choices[:pad])))
        packs.append(pack)
        print(name, '16 pads assembled',flush=True)
    manifest = {'schema':1,'id':'style-starters-v1','stage':'local candidate; upload and listening pending','rights':{'source':'User-supplied archives','user_declaration':'freware,use them as wished,just sort and rename properly','permission':'User expressly requested repository source copies and Roblox style packs','publisher_license_file':None,'independently_verified':False},'processing':'Non-vocal percussion cuts; tonal and FX pads use source-derived harmonic/envelope projection to fixed notes in the declared key. Originals unchanged and retained in the repo.','packs':packs}
    (DEST/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')


def verify():
    manifest=json.loads((DEST/'manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['packs'])==10
    expected={'manifest.json'}
    count=0
    maximum_tuning_cents=0
    tuned=0
    for pack in manifest['packs']:
        assert len(pack['samples'])==16 and pack['id'] in {s.lower() for s in STYLES}
        spec=next(v for k,v in STYLES.items() if k.lower()==pack['id'])
        assert pack['key']==spec[1] and pack['midi_notes']==spec[2], 'Declared key differs from authored kit'
        for sample in pack['samples']:
            for item in [sample,*sample['sources']]:
                path=(ROOT/item['file']).resolve();assert path.is_relative_to(DEST.resolve()) and digest(path)==item['sha256']
                expected.add(str(path.relative_to(DEST)).replace('\\','/'))
            with wave.open(str(ROOT/sample['file']),'rb') as wav:
                assert (wav.getnchannels(),wav.getsampwidth(),wav.getframerate())==(1,2,RATE)
                values=np.frombuffer(wav.readframes(wav.getnframes()),dtype='<i2')
                assert len(values)==sample['frames'] and np.max(np.abs(values.astype(int)))<32767
                assert len(values)>88 and np.any(values)
            if sample['role'] in TONAL:
                expected_note=note_metadata(sample['role'],sample['edits'],0)
                assert sample.get('note')==expected_note['note'] and sample['label']==expected_note['label'], 'Pitch label differs from rendered note'
                assert sample['edits']['target_midi']%12 in {n%12 for n in pack['midi_notes']}
                # All synthesized partials are integer multiples of the target.
                hz=sample['edits']['target_hz'];n=len(values)
                fft_size=2**int(np.ceil(np.log2(n*16)))
                probe=np.abs(np.fft.rfft(values.astype(float)*np.hanning(n),n=fft_size))
                frequencies=np.fft.rfftfreq(fft_size,1/RATE)
                region=np.flatnonzero((frequencies>hz*.8)&(frequencies<hz*1.2))
                peak=int(region[np.argmax(probe[region])])
                a,b,c=np.log(np.maximum(probe[peak-1:peak+2],1e-12))
                offset=.5*(a-c)/(a-2*b+c)
                fundamental=(peak+offset)*RATE/fft_size
                cents=abs(float(1200*np.log2(fundamental/hz)))
                assert cents<10, f'Out-of-key tonal derivative: {sample["id"]}: {cents}'
                maximum_tuning_cents=max(maximum_tuning_cents,cents);tuned+=1
            count+=1
    actual={str(p.relative_to(DEST)).replace('\\','/') for p in DEST.rglob('*') if p.is_file()}
    assert actual==expected
    report={'passed':True,'packs':10,'pads':count,'source_copies':len(expected)-count-1,'derived_clipping':0,'tuned_pads':tuned,'maximum_measured_tuning_cents':maximum_tuning_cents,'keys':[p['key'] for p in manifest['packs']]}
    print(json.dumps(report));return report


def refresh_derived():
    if (ROOT/'data/active-content.json').exists():
        raise RuntimeError('Historical style samples are retired and cannot be regenerated.')
    assert not (ROOT/'docs/evidence/style-starters/user-approval.json').exists(), 'Approved audio is frozen; create a new version for further edits'
    manifest=json.loads((DEST/'manifest.json').read_text(encoding='utf-8'))
    assert manifest['stage'].startswith('local candidate')
    bound=json.loads((ROOT/'data/content-ids.json').read_text(encoding='utf-8'))['Audio']
    assert not any(s['id'] in bound for p in manifest['packs'] for s in p['samples']), 'Do not refresh bound style audio'
    for pack in manifest['packs']:
        tonal_index=0
        ordinals={}
        for sample in pack['samples']:
            assert sample['asset_id'] is None, 'Do not replace an uploaded/reviewed sample'
            decoded=[]
            for item in sample['sources']:
                path=ROOT/item['file'];assert digest(path)==item['sha256'];decoded.append(decode(path))
            n=min(map(len,decoded));data=sum(s[:n] for s in decoded)/len(decoded)
            midi=pack['midi_notes'][tonal_index%4]+(0 if sample['role']=='bass' else 12)
            signal,edits=derive(data,sample['role'],midi)
            if sample['role'] in TONAL:tonal_index+=1
            path=ROOT/sample['file'];save_wav(path,signal)
            sample.update({'sha256':digest(path),'frames':len(signal),'duration_seconds':len(signal)/RATE,'peak_dbfs':float(20*np.log10(max(np.max(np.abs(signal)),1e-9))),'rms_dbfs':float(20*np.log10(max(np.sqrt(np.mean(signal**2)),1e-9))),'edits':edits})
            ordinals[sample['role']]=ordinals.get(sample['role'],0)+1
            sample.pop('note',None)
            sample.update(note_metadata(sample['role'],edits,ordinals[sample['role']]))
    manifest['processing']='Non-vocal percussion cuts; tonal and FX pads use source-derived harmonic/envelope projection to fixed notes in the declared key. Originals unchanged and retained in the repo.'
    (DEST/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')


if __name__=='__main__':
    if (ROOT/'data/active-content.json').exists():
        raise SystemExit('Historical style production is retired. Use the explicit first-pack admission workflow.')
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--music',type=Path,default=Path('C:/Users/slavd/Music'));group=parser.add_mutually_exclusive_group();group.add_argument('--verify',action='store_true');group.add_argument('--refresh-derived',action='store_true');args=parser.parse_args()
    if args.refresh_derived:refresh_derived()
    elif not args.verify: build(args.music)
    verify()
