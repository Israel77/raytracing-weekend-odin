package raytracer

import "core:math"
import "core:math/linalg"
import "core:math/rand"


random_unit_vector ::  proc () -> Vec3 {
    for {
        p := Vec3 {rand.float64_uniform(-1.0, 1.0), rand.float64_uniform(-1.0, 1.0), rand.float64_uniform(-1.0, 1.0)}
        len_squared := linalg.dot(p, p)
        if (1e-160 < len_squared && len_squared <= 1) {
            return p / math.sqrt_f64(len_squared)
        }
    }
}

/*
* Creates a random unit vector on the same hemisphere as the normal
*/
random_unit_on_hemisphere :: proc(normal: Vec3) -> Vec3 {
    unit_vector := random_unit_vector()

    if linalg.dot(unit_vector, normal) >= 0 {
        return unit_vector
    } else {
        return -unit_vector
    }
}
