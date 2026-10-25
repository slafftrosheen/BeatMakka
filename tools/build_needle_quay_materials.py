"""Blender authored material library and neutral swatches; no external texture inputs."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/materials';O.mkdir(exist_ok=True)
D=json.loads((R/'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
L=json.loads((R/'assets/production/materials/layout.json').read_text());slots={s['name']:s for s in L['slots']}
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.world.color=(.3,.3,.3)
bpy.ops.object.camera_add(location=(3,-5,2.8));camera=bpy.context.object;camera.rotation_euler=(-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=3;scene.camera=camera
bpy.ops.object.light_add(type='AREA',location=(2,-3,4));bpy.context.object.data.energy=600;bpy.context.object.data.size=4
bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24);ball=bpy.context.object
for p in ball.data.polygons:p.use_smooth=True
rows=[]
for spec in D['materials']:
 slot=slots[spec['atlas_slot']];m=bpy.data.materials.new(spec['id']+' '+spec['name']);m.use_nodes=True;m.use_fake_user=True;n=m.node_tree.nodes;l=m.node_tree.links;bs=n.get('Principled BSDF')
 rgb=slot['color'];bs.inputs['Base Color'].default_value=(*(pow(v/255,2.2) for v in rgb),1);bs.inputs['Roughness'].default_value=slot['roughness'];bs.inputs['Metallic'].default_value=slot['metalness']
 tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=35;tex.inputs['Detail'].default_value=2
 bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.035;l.new(tex.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],bs.inputs['Normal'])
 if spec['id']=='MAT-05':
  brick=n.new('ShaderNodeTexBrick');brick.inputs['Scale'].default_value=5;brick.inputs['Mortar Size'].default_value=.025;brick.inputs['Color1'].default_value=(.27,.13,.08,1);brick.inputs['Color2'].default_value=(.4,.23,.15,1);brick.inputs['Mortar'].default_value=(.33,.29,.23,1);l.new(brick.outputs['Color'],bs.inputs['Base Color']);l.new(brick.outputs['Fac'],bump.inputs['Height']);bump.inputs['Distance'].default_value=.06
 if spec['id']=='MAT-09':
  ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.065,.14,.12,1);ramp.color_ramp.elements[1].color=(.48,.29,.09,1);l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color']);bs.inputs['Metallic'].default_value=.8;bs.inputs['Roughness'].default_value=.5
 if spec['id']=='MAT-10':
  bs.inputs['Base Color'].default_value=(.65,.28,.045,1);bs.inputs['Roughness'].default_value=.25;bs.inputs['Transmission Weight'].default_value=.25;bs.inputs['Emission Color'].default_value=(.65,.25,.025,1);bs.inputs['Emission Strength'].default_value=.18
 if spec['id'] in ('MAT-03','MAT-04','MAT-11'):
  wave=n.new('ShaderNodeTexWave');wave.wave_type='BANDS';wave.bands_direction='X';wave.inputs['Scale'].default_value=30 if spec['id']=='MAT-11' else 7;wave.inputs['Distortion'].default_value=2;l.new(wave.outputs['Fac'],bump.inputs['Height'])
 ball.data.materials.clear();ball.data.materials.append(m);scene.render.filepath=str(O/(spec['id']+'.png'));bpy.ops.render.render(write_still=True)
 rows.append({**spec,'source':'assets/production/needle-quay/materials/NeedleQuayMaterialLibrary.blend','material_name':m.name,'preview':str((O/(spec['id']+'.png')).relative_to(R)).replace('\\','/'),'stage':'LOCAL_PROCEDURAL_MATERIAL_CANDIDATE','runtime_maps':'Reuse existing atlas for ten families; MAT-05 brick and MAT-09 brass are procedural DCC sources requiring bake on final UVs','art_approved':False})
bpy.ops.wm.save_as_mainfile(filepath=str(O/'NeedleQuayMaterialLibrary.blend'))
(O/'material-manifest.json').write_text(json.dumps({'materials':rows,'atlas_layout':'assets/production/materials/layout.json','existing_basecolor':'assets/production/materials/sets/quay/atlas_basecolor.png','existing_roughness':'assets/production/materials/shared/atlas_roughness.png','existing_metalness':'assets/production/materials/shared/atlas_metalness.png','independent_heavy_pbr_sets_created':0,'roblox_uploaded':False},indent=2)+'\n')
