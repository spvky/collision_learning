package main

import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

sphere_max_in_direction :: proc(s: Sphere, d: Vec3) -> Vec3 {
	return s.xyz + (d * s.w)
}

mesh_max_in_direction :: proc(m: rl.Mesh, d: Vec3) -> Vec3 {
	max_index: int
	max_dot := -math.F32_MAX

	for i in 0 ..< m.vertexCount {
		dot := l.dot(d, m.vertices[i])
		if dot > max_dot {
			max_dot = dot
			max_index = i
		}
	}

	return m.vertices[max_index]
}

support :: proc(s: Sphere, m: rl.Mesh, d: Vec3) {
	a := sphere_max_in_direction(s, d)
	b := mesh_max_in_direction(m, -d)
	return a - b
}
