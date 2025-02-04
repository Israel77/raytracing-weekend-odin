package raytracer

import "core:math"
import "core:math/linalg"

Sphere :: struct {
	center:   Vec3,
	radius:   f64,
	material: Material,
}

Hittable :: union {
	Sphere,
	[]Hittable,
}

HitRecord :: struct {
	front_face: bool,
	point:      Vec3,
	normal:     Vec3,
	t:          f64,
	material:   Material,
}

RaytracerContext :: struct {
	world:  []Hittable,
	camera: Camera,
}

world_init :: proc() -> []Hittable {
	world: [dynamic]Hittable

	material_ground := Lambertian{Color{0.8, 0.8, 0.0}}
	material_center := Lambertian{Color{0.1, 0.2, 0.5}}
    // Glass sphere
	material_left := Dielectric{1.5}
    // Air bubble inside the glass
	material_bubble := Dielectric{1.0 / 1.5}
	material_right := Metal{Color{0.8, 0.6, 0.2}, 1.0}


	append(&world, Hittable(Sphere{Vec3{ 0.0, -100.5, -1.0}, 100, material_ground}))
	append(&world, Hittable(Sphere{Vec3{ 0.0,    0.0, -1.2}, 0.5, material_center}))
	append(&world, Hittable(Sphere{Vec3{-1.0,    0.0, -1.0}, 0.5, material_left  }))
	append(&world, Hittable(Sphere{Vec3{-1.0,    0.0, -1.0}, 0.4, material_bubble}))
	append(&world, Hittable(Sphere{Vec3{ 1.0,    0.0, -1.0}, 0.5, material_right }))

	return world[:]
}

// #region: Hittable methods
hit :: proc(
	self: ^Hittable,
	ray: ^Ray,
	ray_tmin: f64,
	ray_tmax: f64,
) -> (
	record: HitRecord,
	did_hit: bool,
) {
	switch hit_type in self {
	case Sphere:
		sphere := hit_type
		// at² - bt - c = 0
		delta_origin_center := sphere.center - ray.origin
		a := linalg.dot(ray.direction, ray.direction)
		//b := -2.0 * linalg.dot(ray.direction, delta_origin_center)
		// Use h = -b / 2 to simplify calculations
		h := linalg.dot(ray.direction, delta_origin_center)
		c := linalg.dot(delta_origin_center, delta_origin_center) - sphere.radius * sphere.radius

		discriminant := h * h - a * c

		if discriminant < 0 {
			did_hit = false
			return
		}

		sqrt_d := math.sqrt(discriminant)

		// Try the first root
		root := (h - sqrt_d) / a
		if (root <= ray_tmin || ray_tmax <= root) {
			// Try the second root
			root := (h - sqrt_d) / a
			if (root <= ray_tmin || ray_tmax <= root) {
				// Fail if no root meets the criteria
				did_hit = false
				return
			}
		}

		record.material = sphere.material
		record.t = root
		record.point = ray.origin + root * ray.direction
		outward_normal := (record.point - sphere.center) / sphere.radius

		// Sets the remaining fields
		set_face_normal(&record, ray, &outward_normal)
		did_hit = true
		return

	case []Hittable:
		objects := hit_type
		closest_so_far := ray_tmax

		for &object in objects {

			temp_record, temp_hit := hit(&object, ray, ray_tmin, closest_so_far)

			if temp_hit {
				did_hit = true
				closest_so_far = temp_record.t
				record = temp_record
			}
		}

		return
	}

	unreachable()
}

set_face_normal :: proc(self: ^HitRecord, ray: ^Ray, outward_normal: ^Vec3) {
	self.front_face = linalg.dot(ray.direction, outward_normal^) < 0
	self.normal = self.front_face ? outward_normal^ : -outward_normal^
}
