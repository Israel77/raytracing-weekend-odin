package raytracer

Lambertian :: struct {
	albedo: Color,
}

Metal :: struct {
	albedo: Color,
}

Material :: union {
	Lambertian,
	Metal,
}

scatter :: proc(
	material: ^Material,
	ray: ^Ray,
	hit_record: ^HitRecord,
) -> (
	did_scatter: bool,
	scattered: Ray,
	attenuation: Color,
) {

	switch material_type in material {
	case Lambertian:
		direction := random_unit_on_hemisphere(hit_record.normal) + random_unit_vector()

        // Degenerate case
        if is_near_zero(&direction) {
            direction = hit_record.normal
        }

		scattered = Ray{hit_record.point, direction}
		attenuation = material_type.albedo
		did_scatter = true
	case Metal:
		direction := reflect(ray.direction, hit_record.normal)
        scattered = Ray{hit_record.point, direction}
		attenuation = material_type.albedo
		did_scatter = true
	}

	return
}
