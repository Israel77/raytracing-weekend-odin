package raytracer;

import "core:math"
import "core:math/rand"
import "core:math/linalg"

Color :: distinct linalg.Vector3f64
Vec3 :: linalg.Vector3f64

Ray :: struct {
	origin:    Vec3,
	direction: Vec3,
}

ray_color :: proc(ray: ^Ray, world: []Hittable, depth: int) -> Color {

	world_hittable := Hittable(world)
	hit_record, did_hit := hit(&world_hittable, ray, 1e-3, math.inf_f64(1))
	if did_hit {
        direction := random_unit_on_hemisphere(hit_record.normal) + random_unit_vector()
		return 0.5 * ray_color(&Ray{hit_record.point, direction}, world, depth-1)
	}


	unit_direction := linalg.vector_normalize(ray.direction)
	t := 0.5 * (unit_direction.y + 1.0)
	return (1 - t) * Color{1.0, 1.0, 1.0} + t * Color{0.5, 0.7, 1.0}
}
