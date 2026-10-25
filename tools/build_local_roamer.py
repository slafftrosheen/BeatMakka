"""Deterministic, editable Roamer body; matches the existing 22-stud chassis.
Uses the approved quay palette and existing interaction/collision coordinates.
Run with Blender --background --python tools/build_local_roamer.py.
"""
import bpy, math
from mathutils import Matrix, Vector
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
colors = {'Teal':(.18,.43,.40,1), 'Cream':(.87,.81,.66,1), 'Coral':(.78,.38,.28,1),
          'Rubber':(.055,.075,.075,1), 'Glass':(.09,.18,.19,1), 'Brass':(.61,.45,.24,1),
          'Lamp':(1,.71,.32,1), 'RedLamp':(.62,.17,.12,1)}
materials = {}
for name, color in colors.items():
    m=bpy.data.materials.new(name);m.diffuse_color=color;materials[name]=m
def finish(o, name, material, bevel=.07):
    o.name=name;o.data.materials.append(materials[material])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Manufactured edge radius','BEVEL');mod.width=bevel;mod.segments=3
        o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    return o
def box(name, size, at, material, bevel=.07):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(at[0],at[2],at[1]))
    o=bpy.context.object;o.dimensions=(size[0],size[2],size[1]);return finish(o,name,material,bevel)
box('Chassis',(22,1,9),(0,2,0),'Rubber',.2)
box('Coachwork',(19,6,9),(-1.5,5.5,0),'Teal',.3)
box('CreamRoof',(20,.6,9.4),(-1,8.8,0),'Cream',.25)
box('Cab',(3,5,9),(9.5,4.5,0),'Cream',.3)
box('Windshield',(.13,2.6,7),(11.04,6,0),'Glass',.06)
box('FrontBumper',(.55,.55,9.5),(11.05,2.7,0),'Brass',.15)
box('RearBumper',(.55,.55,9.5),(-11.05,2.7,0),'Brass',.15)
for side in (-1,1):
    z=side*4.56
    box('SideWindow',(7,2,.12),(2,6.5,z),'Glass')
    for x in (0,3.5):box('WindowMullion',(.12,2.1,.15),(x,6.5,z),'Cream',.02)
    box('CoralStripe',(19,.4,.12),(-1.5,3.6,z),'Coral',.04)
    box('StudioDoorFrame',(3.5,5,.12),(-6,5,z),'Cream',.08)
    box('StudioDoor',(3.1,4.6,.15),(-6,5,side*4.65),'Teal',.07)
    box('DoorWindow',(2.6,1.9,.1),(-6,6,side*4.75),'Glass',.07)
    box('DoorHandle',(.6,.14,.2),(-5,4.6,side*4.8),'Brass',.04)
    box('DoorStep',(4,.4,1),(-6,2.5,side*4.7),'Rubber',.08)
    for x in (-7,7):
        bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=1.5,depth=.8,location=(x,side*4.5,1.5),rotation=(math.pi/2,0,0))
        finish(bpy.context.object,'Tire','Rubber',.12)
        bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.8,depth=.08,location=(x,side*4.94,1.5),rotation=(math.pi/2,0,0))
        finish(bpy.context.object,'WheelHub','Cream',.05)
    box('Headlight',(.14,.8,1.1),(11.24,4,side*3),'Lamp',.12)
    box('TailLight',(.14,.7,.7),(-11.16,4,side*3.5),'RedLamp',.1)
for x in (-4,1):box('RoofVent',(3,.35,2.5),(x,9.23,0),'Brass',.12)
# Preserve the canonical complete exterior envelope, including hubs and bumpers.
deps=bpy.context.evaluated_depsgraph_get()
points=[o.matrix_world @ Vector(c) for o in bpy.context.scene.objects for c in o.evaluated_get(deps).bound_box]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
shift=Matrix.Translation(Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z)))
scale=Matrix.Diagonal(Vector((22/(hi.x-lo.x),9/(hi.y-lo.y),10/(hi.z-lo.z),1)))
for o in bpy.context.scene.objects:o.matrix_world=scale @ shift @ o.matrix_world
dest=ROOT/'assets/production/needle-quay/models/LOOPVAN-01'
dest.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(dest/'LOOPVAN-01.blend'))
