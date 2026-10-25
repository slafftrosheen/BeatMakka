"""Artbook detail revision of the local Roamer, preserving the 22x9x10 envelope.
Uses the approved quay palette and existing interaction/collision coordinates.
Run with Blender --background --python tools/refine_quay_roamer.py.
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
for side in (-1,1):
    z=side*4.78
    box('CabWindowTrim',(2.65,2.65,.15),(9.1,6,z),'Rubber',.15)
    box('CabSideGlass',(2.35,2.35,.17),(9.1,6,z+side*.09),'Glass',.15)
    box('CabDoorSeam',(.055,4.5,.08),(7.65,4.6,z),'Brass',.015)
    box('CabDoorHandle',(.7,.15,.22),(8.15,4.6,z+side*.12),'Brass',.05)
    box('WingMirrorArm',(.7,.12,.7),(10.25,5.9,side*4.9),'Brass',.04)
    box('WingMirror',(.55,.9,.18),(10.2,6.25,side*5.12),'Rubber',.13)
    box('MirrorGlass',(.44,.74,.04),(10.2,6.25,side*5.23),'Glass',.08)
    box('RainGutter',(19,.14,.25),(-1.5,8.5,side*4.55),'Brass',.035)
    for x in (-8.8,-3.2):
        for y in (3.2,7.6):box('DoorHinge',(.22,.38,.19),(x,y,side*4.7),'Brass',.035)
    for x in (-7,7):
        bpy.ops.mesh.primitive_torus_add(major_radius=1.21,minor_radius=.12,major_segments=32,minor_segments=6,location=(x,side*4.98,1.5),rotation=(math.pi/2,0,0))
        finish(bpy.context.object,'WheelRim','Brass',0)
        for angle in range(0,360,60):
            theta=math.radians(angle)
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.085,location=(x+math.cos(theta)*.48,side*5.02,1.5+math.sin(theta)*.48))
            finish(bpy.context.object,'WheelBolt','Brass',0)
    for x in range(-9,6,2):box('CoachworkRivet',(.08,.08,.12),(x,3.12,z),'Brass',.02)
box('RadiatorRecess',(.18,1.5,5.6),(11.12,4.05,0),'Rubber',.1)
for z in (-2.4,-1.8,-1.2,-.6,0,.6,1.2,1.8,2.4):box('RadiatorSlat',(.25,1.3,.08),(11.22,4.05,z),'Brass',.025)
box('WindshieldDivider',(.16,2.75,.12),(11.15,6,0),'Cream',.03)
for side in (-1,1):
    wiper=box('WindshieldWiper',(.2,.08,2.1),(11.24,5.15,side*1.6),'Rubber',.025)
    wiper.rotation_euler.x=side*.18
for x in (-4,1):
    for z in (-.8,-.4,0,.4,.8):box('RoofVentLouvre',(2.5,.15,.08),(x,9.45,z),'Rubber',.02)
box('StudioStepTread',(3.5,.1,1.1),(-6,2.75,-4.9),'Brass',.04)
# Preserve the canonical complete exterior envelope, including hubs and bumpers.
deps=bpy.context.evaluated_depsgraph_get()
points=[o.matrix_world @ Vector(c) for o in bpy.context.scene.objects for c in o.evaluated_get(deps).bound_box]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
shift=Matrix.Translation(Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z)))
scale=Matrix.Diagonal(Vector((22/(hi.x-lo.x),9/(hi.y-lo.y),10/(hi.z-lo.z),1)))
for o in bpy.context.scene.objects:o.matrix_world=scale @ shift @ o.matrix_world
dest=ROOT/'assets/production/needle-quay/models/refined'
dest.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(dest/'LOOPVAN-01.blend'))
