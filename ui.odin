package main

import "base:intrinsics"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

ACTIVE_TAB_COLOR: rl.Color : {99, 226, 212}
INACTIVE_TAB_COLOR: rl.Color : {48, 153, 156}

Tab_Group :: struct($T: typeid) where intrinsics.type_is_enum(T) {
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

draw_tab_group :: proc(tg: ^Tab_Group($T)) {
	offset: i32 = 0
	for v in tg.backing_enum {
		s_value := fmt.tprintf("%v", v)
		s_string := strings.clone_to_cstring(s_value, allocator = context.temp_allocator)
		text_width := rl.MeasureText(s_string, tg.font_size)
		width := (padding * 2) + text_width
		height := (padding * 2) + tg.font_size
		rl.DrawRectangle()

	}
}
