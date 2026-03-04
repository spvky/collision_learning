package main

import "base:intrinsics"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

ACTIVE_TAB_COLOR: rl.Color : {99, 226, 212, 255}
INACTIVE_TAB_COLOR: rl.Color : {48, 153, 156, 255}

Tab_Group :: struct($T: typeid) where intrinsics.type_is_enum(T) {
	font_color:     rl.Color,
	active_color:   rl.Color,
	inactive_color: rl.Color,
	layout:         Tab_Group_Layout,
	font_size:      i32,
	padding:        i32,
	margin:         i32,
	backing_enum:   T,
	value_ptr:      ^T,
}

Tab_Group_Layout :: enum {
	Row,
	Column,
}

UI_Element :: struct {
	visible: bool,
}

Menu_Panel :: struct {
	using ui: UI_Element,
}

ui_test :: proc() {
	if rl.IsKeyPressed(.TAB) {
		cycle_editor_mode()
	}
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.BeginMode3D(camera)
	draw_grid(20)
	draw_ui()
	rl.EndMode3D()
	rl.EndDrawing()
}

draw_ui :: proc() {
	tab_offset := draw_tab_group(&tg, {50, 50})
}

cycle_editor_mode :: proc() {
	switch em {
	case .Point:
		em = .Edge
	case .Edge:
		em = .Face
	case .Face:
		em = .Point
	}
}

draw_tab_group :: proc(tg: ^Tab_Group($T), position: [2]i32) -> (offset: [2]i32) {
	offset = position
	for v in T {
		s_value := fmt.tprintf("%v", v)
		s_string := strings.clone_to_cstring(s_value, allocator = context.temp_allocator)
		text_width := rl.MeasureText(s_string, tg.font_size)
		width := (tg.padding * 2) + text_width
		height := (tg.padding * 2) + tg.font_size
		color := v == tg.value_ptr^ ? tg.active_color : tg.inactive_color
		rl.DrawRectangle(offset.x, offset.y, width, height, color)
		rl.DrawText(
			s_string,
			offset.x + tg.padding,
			offset.y + tg.padding,
			tg.font_size,
			tg.font_color,
		)

		if tg.layout == .Row {
			offset += {width + tg.margin, 0}
		} else {
			offset += {0, height + tg.margin}
		}
	}
	return
}
