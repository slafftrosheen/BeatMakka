"""Render local user-supplied models and record geometry before adapting them."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];O=R/'work/user-model-previews';O.mkdir(parents=True,exist_ok=True)
files=['classic_vw_combi_van__stylized_asset.glb','city_game_ready_free.glb','barber_shop_-_stylised.glb','low_poly_tavern_interior.glb','low_poly_stage.glb','midi_controller_keyboard.glb','vef_m557_radio.glb']
report=[]
for name in files:
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(R/'assets'/name));objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 points=[o.matrix_world@v.co for o in objects for v in o.data.vertices];lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)));scale=10/max(hi-lo);center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 entries=[]
 for o in objects:
  mat=o.matrix_world.copy();entries.append({'name':o.name,'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'materials':[m.name for m in o.data.materials]})
  for v in o.data.vertices:v.co=(mat@v.co-center)*scale
  o.parent=None;o.matrix_world=Matrix.Identity(4)
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.render.resolution_x=640;scene.render.resolution_y=480;scene.render.resolution_percentage=100;scene.world=bpy.data.worlds.new('Preview');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.6,.66,.72,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
 bpy.ops.object.light_add(type='AREA',location=(2,-5,12));bpy.context.object.data.energy=1800;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=10
 bpy.ops.object.camera_add(location=(12,-15,11));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,2.3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=13;scene.camera=camera;scene.render.filepath=str(O/(Path(name).stem+'.png'));bpy.ops.render.render(write_still=True)
 report.append({'file':'assets/'+name,'sha256':hashlib.sha256((R/'assets'/name).read_bytes()).hexdigest(),'bounds':list(hi-lo),'objects':entries})
(O/'inventory.json').write_text(json.dumps(report,indent=2))
