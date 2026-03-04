package main

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
	center := payload.position
	collision_object: Collision_Object
	collision_object.center = center
	collision_object.verts = make([dynamic]Vec3, 0, 8)
	collision_object.faces = make([dynamic]Collision_Triangle, 0, 12)

	switch payload.prefab_added {
	case .Cube:
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
			{0, 1, 2},
			{2, 3, 0},
			// Bottom
			{7, 6, 5},
			{5, 4, 7},
			// Front
			{0, 3, 7},
			{7, 4, 0},
			// Back
			{5, 6, 2},
			{2, 1, 5},
			// Left
			{5, 1, 0},
			{0, 4, 5},
			// Right
			{7, 3, 2},
			{2, 6, 7},
		}
		append_elems(&collision_object.verts, ..verts[:])
		append_elems(&collision_object.faces, ..faces[:])

	case .Ramp:
	case .Tetrahedron:
	}
	// inset into dirty objects array
}

Collision_Triangle :: [3]int

Collision_Object :: struct {
	center: Vec3,
	verts:  [dynamic]Vec3,
	faces:  [dynamic]Collision_Triangle,
}
