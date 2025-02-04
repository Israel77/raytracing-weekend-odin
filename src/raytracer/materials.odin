package raytracer

import "core:math" 
import "core:math/rand" 
import "core:math/linalg" 

Lambertian :: struct {
	albedo: Color,
}

Metal :: struct {
	albedo: Color,
    fuzz: f64,
}

Dielectric :: struct {
    refraction_index: f64
}

Material :: union {
	Lambertian,
	Metal,
    Dielectric,
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
		reflected := reflect(ray.direction, hit_record.normal)
		direction := reflected / linalg.length(reflected) + (material_type.fuzz * random_unit_vector())
        scattered = Ray{hit_record.point, direction}
		attenuation = material_type.albedo
		did_scatter = true
    case Dielectric:
        attenuation = {1.0, 1.0, 1.0}
        refraction_index: f64 = hit_record.front_face ? (1.0/material_type.refraction_index) : material_type.refraction_index

        unit_direction := unit_vector(ray.direction)
        cos_theta := math.min(linalg.dot(-unit_direction, hit_record.normal), 1.0)
        sin_theta := math.sqrt(1 - cos_theta * cos_theta)
        
        direction: Vec3
        if (refraction_index * sin_theta > 1.0) || dielectric_reflectance(cos_theta, refraction_index) > rand.float64() {
            direction = reflect(unit_direction, hit_record.normal)
        } else {
            direction = refract(unit_direction, hit_record.normal, refraction_index)
        }

        scattered = Ray{hit_record.point, direction}
        did_scatter = true
	}

	return
}

// Schlick approximation to reflectance
dielectric_reflectance :: proc(cosine: f64, refraction_index: f64) -> f64 {
    r0 := (1 - refraction_index) / (1 + refraction_index)
    r0 = r0 * r0
    return r0 + (1 - r0) * math.pow((1 - cosine), 5)
}
