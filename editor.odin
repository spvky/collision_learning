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
	events.event_listeners = make(map[Editor_Event][dynamic]Editor_Event_Callback, 8)
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
	data: Editor_Action,
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
	switch payload.prefab_added {
	case .Cube:
	case .Ramp:
	case .Tetrahedron:
	}
}

Collision_Object :: struct {
	verts:   [dynamic]Vec3,
	indeces: [dynamic]int,
}
