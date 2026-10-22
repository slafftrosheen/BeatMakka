"""Normalize the B11-B20 Tripo candidates without modifying provider source files."""
import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
SPECS={
 'P06':('assets/candidates/tripo-out/b11-p06-storage-crate-add32aad/model.glb',(3.0,3.0,3.0),-90,'floor-center'),
 'P07':('assets/candidates/tripo-out/b12-p07-headphones-6e5357d9/model.glb',(2.0,0.8,1.5),-90,'floor-center'),
 'P11':('assets/candidates/tripo-out/b13-p11-planter-pot-daea9589/model.glb',(2.0,2.0,2.5),0,'floor-center'),
 'P12':('assets/candidates/tripo-out/b14-p12-broad-leaf-plant-eebbc149/model.glb',(3.0,3.0,4.0),0,'floor-center'),
 'P13':('assets/candidates/tripo-out/b15-p13-lamp-core-09cb43ae/model.glb',(1.5,1.5,2.0),-90,'rear-center'),
 'P14':('assets/candidates/tripo-out/b16-p14-utility-junction-box-d57e4c07/model.glb',(2.0,1.0,3.0),-90,'rear-center'),
 'P16':('assets/candidates/tripo-out/b17-p16-rooftop-vent-c6945d18/model.glb',(3.0,2.0,3.0),-90,'floor-center'),
 'I01':('assets/candidates/tripo-out/b18-i01-metal-strike-sign-b931a097/model.glb',(3.0,0.3,2.0),-90,'upper-hinge'),
 'I04':('assets/candidates/tripo-out/b19-i04-resonator-junction-0b2aa08d/model.glb',(3.0,1.5,4.0),-90,'rear-center'),
 'I05':('assets/candidates/tripo-out/b20-i05-listening-podium-d89353d8/model.glb',(3.0,2.0,4.0),-90,'floor-center'),
}
CAPS={'P06':350,'P07':1000,'P11':400,'P12':550,'P13':500,'P14':400,'P16':500,'I01':300,'I04':650,'I05':800}

def bounds(meshes):
    pts=[o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    return [min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]

def normalize(aid):
    src_rel,target,yaw,pivot=SPECS[aid]; src=ROOT/src_rel
    outdir=ROOT/'assets/cleaned'/aid; outdir.mkdir(parents=True,exist_ok=True)
    stem=f'{aid}_normalized_geometry_candidate'
    out=outdir/f'{stem}.glb'; blend=outdir/f'{stem}.blend'; preview=outdir/f'{stem}_preview.png'
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(src))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if not meshes: raise RuntimeError(f'{aid}: no mesh in {src_rel}')
    for o in meshes:
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    if len(meshes)>1:bpy.ops.object.join()
    obj=bpy.context.view_layer.objects.active; obj.name=f'{aid}_GeometryCandidate'; obj.data.name=f'{aid}_GeometryCandidateMesh'
    ang=math.radians(yaw); c,s=math.cos(ang),math.sin(ang)
    points=[]
    for v in obj.data.vertices:
        x,y,z=v.co; points.append(Vector((c*x-s*y,s*x+c*y,z)))
    mins=[min(p[i] for p in points) for i in range(3)]; maxs=[max(p[i] for p in points) for i in range(3)]
    dims=[maxs[i]-mins[i] for i in range(3)]
    if min(dims)<1e-8:raise RuntimeError(f'{aid}: degenerate geometry {dims}')
    scale=[target[i]/dims[i] for i in range(3)]
    scaled=[Vector((p.x*scale[0],p.y*scale[1],p.z*scale[2])) for p in points]
    mins=[min(p[i] for p in scaled) for i in range(3)]; maxs=[max(p[i] for p in scaled) for i in range(3)]
    cx=(mins[0]+maxs[0])/2; cy=(mins[1]+maxs[1])/2; cz=(mins[2]+maxs[2])/2
    if pivot=='floor-center': origin=Vector((cx,cy,mins[2]))
    elif pivot=='rear-center': origin=Vector((cx,maxs[1],cz))
    elif pivot=='upper-hinge': origin=Vector((cx,maxs[1],maxs[2]))
    else: raise ValueError(pivot)
    for v,p in zip(obj.data.vertices,scaled):v.co=p-origin
    obj.data.update()
    bm=bmesh.new(); bm.from_mesh(obj.data); bmesh.ops.recalc_face_normals(bm,faces=bm.faces); bm.to_mesh(obj.data); bm.free()
    obj.location=(0,0,0); obj.rotation_euler=(0,0,0); obj.scale=(1,1,1)
    obj['asset_id']=aid; obj['stage']='DCC normalized geometry candidate'; obj['target_blender_dimensions_xyz']=target; obj['pivot']=pivot; obj['source_glb']=src_rel
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_materials='EXPORT',export_yup=True,export_apply=True,use_selection=True)
    scene=bpy.context.scene; scene.render.engine='BLENDER_WORKBENCH'; scene.render.resolution_x=768; scene.render.resolution_y=768; scene.render.resolution_percentage=100; scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True
    scene.display.shading.light='STUDIO'; scene.display.shading.show_shadows=True; scene.display.shading.show_cavity=True; scene.display.shading.cavity_type='BOTH'; scene.display.shading.color_type='MATERIAL'
    target_z=target[2]*0.5 if pivot=='floor-center' else (-target[2]*0.5 if pivot=='upper-hinge' else 0.0); target_pos=Vector((0,0,target_z)); span=max(target)
    camdata=bpy.data.cameras.new('CandidatePreviewCamera'); cam=bpy.data.objects.new('CandidatePreviewCamera',camdata); scene.collection.objects.link(cam); cam.location=(span*0.7,-span*2.4,target[2]*1.25); cam.rotation_euler=(target_pos-cam.location).to_track_quat('-Z','Y').to_euler(); camdata.type='ORTHO'; camdata.ortho_scale=span*1.4; scene.camera=cam; scene.render.filepath=str(preview); bpy.ops.render.render(write_still=True)
    tri=sum(len(p.vertices)-2 for p in obj.data.polygons)
    return {'asset_id':aid,'raw_source':src_rel,'normalized_glb':out.relative_to(ROOT).as_posix(),'editable_blend':blend.relative_to(ROOT).as_posix(),'neutral_preview':preview.relative_to(ROOT).as_posix(),'target_blender_bounds_xyz':list(target),'target_game_dimensions_w_h_d':[target[0],target[2],target[1]],'pivot':pivot,'yaw_degrees_applied':yaw,'triangles':tri,'triangle_cap':CAPS[aid],'within_triangle_cap':tri<=CAPS[aid],'mesh_objects':1,'materials':[m.name for m in obj.data.materials if m],'uv_layers':[u.name for u in obj.data.uv_layers],'stage':'DCC normalized geometry candidate; palette, part separation, art review and Studio/runtime acceptance pending'}

results=[normalize(aid) for aid in SPECS]
receipt={'blender_version':bpy.app.version_string,'assets':results}
(ROOT/'docs/evidence/dcc-normalization/remaining-batch.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,indent=2))
