package main

import "core:fmt"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

checked_points: [dynamic]Vec3

Simplex :: struct {
	a, b, c, d: Vec3,
	count:      int,
}

test_simplex: Simplex

VEC0 :: Vec3{0, 0, 0}


draw_simplex :: proc(s: ^Simplex) {
	switch s.count {
	case 1:
		rl.DrawSphere(s.a, 0.25, rl.WHITE)
	case 2:
		rl.DrawSphere(s.a, 0.25, rl.RED)
		rl.DrawSphere(s.b, 0.25, rl.WHITE)

		rl.DrawLine3D(s.a, s.b, rl.RED)
	case 3:
		rl.DrawSphere(s.a, 0.25, rl.RED)
		rl.DrawSphere(s.b, 0.25, rl.RED)
		rl.DrawSphere(s.c, 0.25, rl.WHITE)

		rl.DrawLine3D(s.a, s.b, rl.RED)
		rl.DrawLine3D(s.a, s.c, rl.RED)
		rl.DrawLine3D(s.b, s.c, rl.RED)
	case 4:
		rl.DrawSphere(s.a, 0.25, rl.RED)
		rl.DrawSphere(s.b, 0.25, rl.RED)
		rl.DrawSphere(s.c, 0.25, rl.RED)
		rl.DrawSphere(s.d, 0.25, rl.WHITE)

		rl.DrawLine3D(s.a, s.b, rl.RED)
		rl.DrawLine3D(s.a, s.c, rl.RED)
		rl.DrawLine3D(s.b, s.c, rl.RED)

		rl.DrawLine3D(s.a, s.d, rl.RED)
		rl.DrawLine3D(s.b, s.d, rl.RED)
		rl.DrawLine3D(s.c, s.d, rl.RED)
	}

	for vert in checked_points {
		rl.DrawSphere(vert, 0.25, rl.GOLD)
	}
}

reset_simplex :: proc(s: ^Simplex) {
	s.a = VEC0
	s.b = VEC0
	s.c = VEC0
	s.d = VEC0
	s.count = 0
}

append_to_simplex :: proc(s: ^Simplex, point: Vec3) {
	s.a, s.b, s.c, s.d = point, s.a, s.b, s.c
	s.count += 1
}

sphere_max_in_direction :: proc(s: Sphere, d: Vec3) -> Vec3 {
	norm_d := l.normalize0(d)
	point := s.xyz + (norm_d * s.w)
	append(&checked_points, point)
	return point
}

mesh_max_in_direction :: proc(m: rl.Mesh, d: Vec3) -> Vec3 {
	max_index: int
	max_dot: f32 = -math.F32_MAX

	vert_slice := (cast([^]Vec3)m.vertices)[:m.vertexCount]
	for vertex, i in vert_slice {
		dot := l.dot(d, vertex)
		if dot > max_dot {
			max_dot = dot
			max_index = i
		}
	}
	append(&checked_points, vert_slice[max_index])
	return vert_slice[max_index]
}

support :: proc(s: Sphere, m: rl.Mesh, d: Vec3) -> Vec3 {
	a := sphere_max_in_direction(s, d)
	b := mesh_max_in_direction(m, -d)
	return a - b
}

same_direction :: proc(a, b: Vec3) -> bool {
	return l.dot(a, b) > 0
}

gjk :: proc(a: Sphere, b: rl.Mesh, s: ^Simplex) -> (overlap: bool) {
	checked_points = make([dynamic]Vec3, 0, 16)
	reset_simplex(s)
	d := Vec3{1, 0, 0}
	append_to_simplex(s, support(a, b, d))
	d = -s.a

	max_iterations := 64
	iterations: int

	for iterations < max_iterations {
		// fmt.printfln("Entering Iteration %v with a direction of %v", iterations, d)
		append_to_simplex(s, support(a, b, d))
		if l.dot(s.a, d) <= 0 {
			fmt.printfln("No Collision, Terminatng: %v", s)
			return
		}

		switch s.count {
		case 2:
			d = gjk_line(s)
		case 3:
			d = gjk_triangle(s)
		case 4:
			overlap, d = gjk_tetrahedron(s)
		}
		if overlap {
			return
		}
		iterations += 1
	}
	return
}

gjk_line :: proc(s: ^Simplex) -> (d: Vec3) {
	ab := s.b - s.a
	ao := -s.a
	if same_direction(ab, ao) {
		// Origin Is on the line
		d = l.vector_triple_product(ab, ao, ab)
	} else {
		d = ao
		s.count = 1
	}
	return
}

gjk_triangle :: proc(s: ^Simplex) -> (d: Vec3) {
	// Normal of Triangle ABC
	abc := l.cross(s.b - s.a, s.c - s.a)
	ac := s.c - s.a
	ao := -s.a

	if same_direction(l.cross(abc, ac), ao) {
		if same_direction(ac, ao) {
			// Origin is nearest AC
			s.b = s.c
			s.count = 2
			d = l.vector_triple_product(ac, ao, ac)
			return
		}
	} else {
		ab := s.b - s.a
		if same_direction(l.cross(ab, abc), ao) {
			if same_direction(ab, ao) {
				s.count = 2
				d = l.vector_triple_product(ab, ao, ab)
				return
			} else {
				s.count = 1
				d = ao
				return
			}
		} else {
			if same_direction(abc, ao) {
				d = abc
				return
			} else {
				s.b, s.c = s.c, s.b
				d = -abc
				return
			}
		}
	}
	return
}

gjk_tetrahedron :: proc(s: ^Simplex) -> (overlap: bool, d: Vec3) {
	ab := s.b - s.a
	ac := s.c - s.a
	ad := s.d - s.a
	ao := -s.a
	bo := -s.b

	abc := l.cross(ab, ac)
	acd := l.cross(ac, ad)
	adb := l.cross(ad, ab)

	if same_direction(abc, ao) {
		// Origin is nearest to triangle ABC
		s.count = 3
		d = gjk_triangle(s)
	}

	if same_direction(acd, ao) {
		// Origin nearest ACD
		s.b, s.c = s.d, s.b
		s.count = 3
		d = gjk_triangle(s)
	}

	if same_direction(adb, ao) {
		// Origin is nearest ADB
		s.b, s.c = s.d, s.b
		s.count = 3
		d = gjk_triangle(s)
	}

	overlap = true
	return
}
