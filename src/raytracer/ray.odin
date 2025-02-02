package raytracer;

import "core:math/linalg"
import "core:math"

Color :: distinct linalg.Vector3f64
Vec3 :: linalg.Vector3f64

Ray :: struct {
	origin:    Vec3,
	direction: Vec3,
}

Hittable :: union {
	Sphere,
	[]Hittable,
}

ray_color :: proc(ray: ^Ray, world: []Hittable) -> Color {

	world_hittable := Hittable(world)
	hit_record, did_hit := hit(&world_hittable, ray, 0.0, math.inf_f64(1))
	if did_hit {
		return 0.5 * (Color(hit_record.normal) + Color{1.0, 1.0, 1.0})
	}


	unit_direction := linalg.vector_normalize(ray.direction)
	t := 0.5 * (unit_direction.y + 1.0)
	return (1 - t) * Color{1.0, 1.0, 1.0} + t * Color{0.5, 0.7, 1.0}
}
