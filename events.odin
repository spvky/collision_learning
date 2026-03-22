package main

// import "core:container/queue"
// import "core:log"
//
// Event :: struct {
// 	type:    Event_Type,
// 	payload: Event_Payload,
// }
//
// Event_Type :: enum {
// 	Player_Collision,
// }
//
// Event_Payload :: union {
// 	Player_Collision_Payload,
// }
//
// Player_Collision_Payload :: struct {
// 	point:  Vec3,
// 	normal: Vec3,
// 	mtv:    f32,
// }
//
// Event_Callback :: proc(event: Event)
//
// init_events_system :: proc() {
// 	world.event_listeners = make(map[Event_Type][dynamic]Event_Callback, 8)
// 	queue.reserve(&world.event_queue, 16)
// }
