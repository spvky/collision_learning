package main

import "core:fmt"
import l "core:math/linalg"
import rl "vendor:raylib"

import "core:container/queue"

Event_Manager :: struct {
	event_queue:     queue.Queue(Editor_Event),
	event_listeners: map[Editor_Event_Type][dynamic]Editor_Event_Callback,
}

events: Event_Manager

Editor_Event :: struct {
	type:    Editor_Event_Type,
	payload: Editor_Event_Payload,
}

Editor_Event_Type :: enum {
	Add_Prefab,
}

Editor_Event_Payload :: union {
	Add_Prefab_Payload,
}

Collision_Object_Component :: union {
	Component_Vert,
	Component_Edge,
	Component_Triangle,
}

Component_Vert :: struct {
	object_idx: int,
	vert_idx:   int,
}

Component_Edge :: struct {
	object_idx: int,
	start_idx:  int,
	end_idx:    int,
}

Component_Triangle :: struct {
	object_idx: int,
	vert_idx:   int,
}

Editor_Event_Callback :: proc(event: Editor_Event)


init_editor_event_manager :: proc() {
	events.event_listeners = make(map[Editor_Event_Type][dynamic]Editor_Event_Callback, 8)
	queue.reserve(&events.event_queue, 16)
}

delete_editor_event_manager :: proc() {
	for v in Editor_Event_Type {
		delete(events.event_listeners[v])
	}
	delete(events.event_listeners)
	queue.destroy(&events.event_queue)
}

publish_event :: proc(event: Editor_Event) {
	queue.enqueue(&events.event_queue, event)
}

subscribe_event :: proc(event_type: Editor_Event_Type, callback: Editor_Event_Callback) {
	if event_type not_in events.event_listeners {
		events.event_listeners[event_type] = make([dynamic]Editor_Event_Callback, 0, 2)
	}
	append(&events.event_listeners[event_type], callback)
}

process_events :: proc() {
	for queue.len(events.event_queue) > 0 {
		event := queue.dequeue(&events.event_queue)
		if listeners, ok := events.event_listeners[event.type]; ok {
			for callback in listeners {
				callback(event)
			}
		}
	}
}

Undo_List :: struct {
	head: ^Undo_Node,
	tail: ^Undo_Node,
}

Undo_Node :: struct {
	data: Editor_Event,
	next: ^Undo_Node,
}

Prefab_Kind :: enum {
	Cube,
	Ramp,
	Tetrahedron,
}

Add_Prefab_Payload :: struct {
	position:     Vec3,
	prefab_added: Prefab_Kind,
	prefab_ptr:   ^Collision_Object,
}

add_prefab :: proc(event: Editor_Event) {
	payload := event.payload.(Add_Prefab_Payload)
	collision_object: Collision_Object

	switch payload.prefab_added {
	case .Cube:
		init_cube(&collision_object, payload.position)
	case .Ramp:
	case .Tetrahedron:
	}
	append(&collision_objects, collision_object)
	// inset into dirty objects array
}

init_cube :: proc(collision_object: ^Collision_Object, center: Vec3) {
	collision_object.center = center
	collision_object.verts = make([dynamic]Vec3, 0, 8)
	collision_object.faces = make([dynamic]Collision_Triangle, 0, 12)
	verts := [?]Vec3 {
		// Top Verts
		{-1, 1, -1},
		{-1, 1, 1},
		{1, 1, 1},
		{1, 1, -1},
		// Bottom Verts
		{-1, -1, -1},
		{-1, -1, 1},
		{1, -1, 1},
		{1, -1, -1},
	}

	faces := [?]Collision_Triangle {
		// Top
		{0, 1, 3},
		{1, 2, 3},
		// Bottom
		{4, 7, 5},
		{7, 6, 5},
		// Front
		{0, 3, 7},
		{7, 4, 0},
		// Back
		{2, 1, 6},
		{1, 5, 6},
		// Left
		{6, 3, 2},
		{6, 7, 3},
		// Right
		{1, 0, 5},
		{4, 5, 0},
	}
	append_elems(&collision_object.verts, ..verts[:])
	append_elems(&collision_object.faces, ..faces[:])
}

Collision_Triangle :: [3]int

Collision_Object :: struct {
	center: Vec3,
	verts:  [dynamic]Vec3,
	faces:  [dynamic]Collision_Triangle,
}

collision_objects: [dynamic]Collision_Object

init_collision_objects :: proc() {
	collision_objects = make([dynamic]Collision_Object, 0, 8)
	collision_object: Collision_Object
	init_cube(&collision_object, {0, -2, 0})
	append(&collision_objects, collision_object)
}

collision_object_raycast :: proc() -> (hit: bool, component: Collision_Object_Component) {
	ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
	if rl.IsMouseButtonPressed(.LEFT) {
		for obj, i in collision_objects {
			component_vert := Component_Vert {
				object_idx = i,
			}
			switch em {
			case .Point:
				for v, ii in obj.verts {
					component_vert.vert_idx = ii
					pos := v + obj.center
					hit_info := rl.GetRayCollisionSphere(ray, pos, 0.15)
					if hit_info.hit {
						hit = true
						component = component_vert
						return
					}
				}
			case .Edge:
			case .Face:
			}
		}
	}
	return
}

render_collision_objects :: proc(show_normals := false) {
	for obj, i in collision_objects {
		for tri in obj.faces {
			color := rl.RED
			a := obj.verts[tri[0]] + obj.center
			b := obj.verts[tri[1]] + obj.center
			c := obj.verts[tri[2]] + obj.center
			rl.DrawLine3D(a, b, color)
			rl.DrawLine3D(a, c, color)
			rl.DrawLine3D(b, c, color)
			if show_normals {
				center := (a + b + c) / 3
				normal := l.normalize(l.cross(b - a, c - a))
				rl.DrawLine3D(center, center + normal, rl.YELLOW)
			}
			if em == .Point {
				for vert, ii in obj.verts {
					color := rl.WHITE
					switch v in selected_component {
					case Component_Vert:
						if v.object_idx == i && v.vert_idx == ii {
							color = rl.BLUE
						}
					case Component_Edge:
					case Component_Triangle:
					}
					rl.DrawSphere(vert + obj.center, 0.15, color)
				}
			}
		}
	}
}

draw_scene :: proc() {
	rl.BeginMode3D(camera)
	// draw_grid(20)
	frametime := rl.GetFrameTime()
	delta: Vec3
	if rl.IsKeyDown(.LEFT) {
		delta.x += 1
	}
	if rl.IsKeyDown(.RIGHT) {
		delta.x -= 1
	}
	if rl.IsKeyDown(.UP) {
		delta.y += 1
	}
	if rl.IsKeyDown(.DOWN) {
		delta.y -= 1
	}
	collision_objects[0].verts[0] += delta * frametime
	render_collision_objects()
	rl.EndMode3D()
}
