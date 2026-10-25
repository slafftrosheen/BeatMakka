"""Blender texture preparation from the user's supplied stylized material pack.
Copies source maps; produces 512px color and 256px auxiliary tiles.
No generative image edits, provider calls or uploads.
"""
import bpy, json, shutil, hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=Path('C:/Users/slavd/OneDrive/Pictures/Assets/Stylized Materials Library -/BD_StyleMat(JPG)/textures')
V=R/'assets/sources/user-materials/quay-environment'
O=R/'assets/production/needle-quay/surface-tiles';O.mkdir(parents=True,exist_ok=True)
families={'brick':'Wall_5','plaster':'Wall_3','wood':'Wood_6','stone':'floor_tiles_1','canvas':'Fabric_1','metal':'metal_3_D'}
records=[]
for family,source in families.items():
    for channel,needle in [('color','basecolor'),('normal','normal'),('rough','roughness')]:
        matches=sorted(p for p in (S/source).glob('*.jpg') if needle in p.stem.lower())
        p=matches[0];vendor=V/source/p.name;vendor.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,vendor)
        im=bpy.data.images.load(str(vendor),check_existing=False)
        im.colorspace_settings.name='sRGB' if channel=='color' else 'Non-Color'
        size=512 if channel=='color' else 256
        im.scale(size,size)
        # Quiet broad paint: retain the supplied surface variation without uniform rust.
        if family in ('plaster','canvas') and channel=='color':
            values=list(im.pixels[:])
            for i in range(0,len(values),4):
                luminance=.2126*values[i]+.7152*values[i+1]+.0722*values[i+2]
                value=.82+.18*luminance
                values[i]=values[i+1]=values[i+2]=value
            im.pixels[:]=values
        if family in ('stone','brick') and channel=='color':
            values=list(im.pixels[:])
            for i in range(0,len(values),4):
                luminance=.2126*values[i]+.7152*values[i+1]+.0722*values[i+2]
                if family=='stone':
                    value=.4+.4*max(0,luminance)**.5
                    values[i:i+3]=[value,value*.95,value*.86]
                else:
                    value=.3+.6*luminance
                    values[i:i+3]=[min(1,value*1.12),value*.74,value*.57]
            im.pixels[:]=values
        if family=='plaster' and channel=='normal':
            values=list(im.pixels[:])
            for i in range(0,len(values),4):
                values[i]=.5+(values[i]-.5)*.25
                values[i+1]=.5+(values[i+1]-.5)*.25
            im.pixels[:]=values
        dest=O/f'{family}_{channel}.png';im.filepath_raw=str(dest);im.file_format='PNG';im.save()
        records.append({'family':family,'channel':channel,'original':str(p),'vendored':str(vendor.relative_to(R)).replace('\\','/'),'source_sha256':hashlib.sha256(vendor.read_bytes()).hexdigest(),'output':str(dest.relative_to(R)).replace('\\','/'),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
        bpy.data.images.remove(im)
(O/'provenance.json').write_text(json.dumps({'source':'User-supplied BD_StyleMat(JPG) library','maps':records,'target_resolution':{'color':512,'normal':256,'rough':256},'uploaded':False},indent=2))
