module main
import os
import math
import gfx

////////////////////////////////////////////////////////////////////////////////////////
// Comment out lines in array below to prevent re-rendering every scene.
// If you create a new scene file, add it to the list below.
//
// NOTE: **BEFORE** you submit your solution, uncomment all lines, so
//       your code will render all the scenes!

const (
    scene_filenames = [
        'P02_00_sphere',
        'P02_01_sphere_ambient',
        'P02_02_sphere_room',
        'P02_03_quad',
        'P02_04_quad_room',
        'P02_05_ball_on_plane',
        'P02_06_balls_on_plane',
        'P02_07_reflections',
        'P02_08_antialiased',
        'P02_09_cube',
        'P02_10_refraction',
        'P02_11_creativeartifact',
        'P02_12_triangle'
    ]
)


////////////////////////////////////////////////////////////////////////////////////////
// module aliasing to make code a little easier to read
// ex: replacing `gfx.Scene` with just `Scene`

type Point     = gfx.Point
type Vector    = gfx.Vector
type Direction = gfx.Direction
type Normal    = gfx.Normal
type Ray       = gfx.Ray
type Color     = gfx.Color
type Image     = gfx.Image
type Frame     = gfx.Frame

type Intersection = gfx.Intersection
type Surface      = gfx.Surface
type Scene        = gfx.Scene

////////////////////////////////////////////////////////////////////////////////////////
// functions to implement


fn intersect_ray_surface(surface Surface, ray Ray) Intersection {
    if surface.shape == gfx.Shape.sphere{
        ec := surface.frame.o.vector_to(ray.e)
        //ec := ray.e.vector_to(surface.frame.o)
        
        a := ray.d.dot(ray.d) // normalized magnitude squared is 1
        b := 2.0 * ray.d.dot(ec)    
        c := ec.dot(ec) - surface.radius * surface.radius
        
        d := (b * b) - (4.0 * a * c)

        if d < 0 {
            return gfx.no_intersection
        }
        mut t := 0.0
        t1 := (-b + math.sqrt(d))/(2*a)
        t2 := (-b - math.sqrt(d))/(2*a) 

    
        if t2 >= ray.t_min && t2 <= ray.t_max{
            t = t2
        }
        else{
            t = t1
        }

        p := ray.e.add(ray.d.scale(t))
        if surface.radius == 0{
            
        }
        n:= p.direction_to(surface.frame.o).scale(1/surface.radius)
        frame := gfx.frame_oz(p, n.as_direction())
        intersection := Intersection{frame, surface, ray.e.distance_to(p)}
        return intersection
    }
    
    if surface.shape == gfx.Shape.quad{
        ec := ray.e.vector_to(surface.frame.o)
        //ec := surface.frame.o.vector_to(ray.e)
        n:= surface.frame.z.scale(-1)
        if (ray.d.dot(n)) == 0{
           return gfx.no_intersection
        }
        t := (ec.dot(n))/(ray.d.dot(n))

        if !(t > ray.t_min && t < ray.t_max){
           return gfx.no_intersection
        }
        p := ray.e.add(ray.d.scale(t))
         
        temp := math.max(math.abs(p.x - surface.frame.o.x), math.abs(p.y - surface.frame.o.y))
        inf_d := math.max(math.abs(p.z - surface.frame.o.z), temp)
        if inf_d > surface.radius{
           return gfx.no_intersection
        }
        frame:= gfx.frame_oz(p, n.as_direction())
        intersection := Intersection{frame, surface, ray.e.distance_to(p)}

        return intersection
    }



    if surface.shape == gfx.Shape.cube {
   
        mut quads := []Point{}
        quads << surface.frame.o.add(surface.frame.x.as_vector())
        quads << surface.frame.o.sub(surface.frame.x.as_vector())
        quads << surface.frame.o.add(surface.frame.y.as_vector())
        quads << surface.frame.o.sub(surface.frame.y.as_vector())
        quads << surface.frame.o.add(surface.frame.z.as_vector())
        quads << surface.frame.o.sub(surface.frame.z.as_vector())

        mut normals := []gfx.Direction{}
        normals << [surface.frame.x, surface.frame.x.scale(-1.0).as_direction(),
                    surface.frame.y, surface.frame.y.scale(-1.0).as_direction(),
                    surface.frame.z, surface.frame.z.scale(-1.0).as_direction() ]
        
        mut intersections := []Intersection{}
        for i in 0..6{
            ec := ray.e.vector_to(quads[i])
            n:= normals[i].scale(-1)
            if (ray.d.dot(n)) == 0{
                continue
            }
            t := (ec.dot(n))/(ray.d.dot(n))

            if !(t > ray.t_min && t < ray.t_max){
                continue
            }
            p := ray.e.add(ray.d.scale(t))
            
            temp := math.max(math.abs(p.x - quads[i].x), math.abs(p.y -  quads[i].y))
            inf_d := math.max(math.abs(p.z -  quads[i].z), temp)
            if inf_d > surface.radius{
                continue
            }
            frame:= gfx.frame_oz(p, n.as_direction())

            intersection := Intersection{frame, surface, ray.e.distance_to(p)}
            intersections << intersection
        }
        if intersections.len == 0{
            return gfx.no_intersection
        }
        mut closest := intersections[0]
        for intersection in intersections{
            if intersection.distance < closest.distance{
                closest = intersection
            }
        }
        return closest
    }
    if surface.shape == gfx.Shape.triangle {
        //points
        half := surface.radius / 2.0
        height := half * math.sqrt(3.0)
        pa := surface.frame.o.add(surface.frame.x.scale(-half))
        pb := surface.frame.o.add(surface.frame.x.scale(half))
        pc := surface.frame.o.add(surface.frame.y.scale(height))

        //edges 
        ea := pa.vector_to(pc)
        eb := pb.vector_to(pc)  
        ee := ray.e.vector_to(pc)

        t := ee.cross(ea).dot(eb) / ray.d.cross(eb).dot(ea)
        a := ray.d.cross(eb).dot(ee) / ray.d.cross(eb).dot(ea)
        b := ee.cross(ea).dot(ray.d) / ray.d.cross(eb).dot(ea)

        if a < 0{
            return gfx.no_intersection
        } 
        if b < 0{
            return gfx.no_intersection
        }
        if a + b > 1{
            return gfx.no_intersection
        }
        if !(t > ray.t_min && t < ray.t_max){
            return gfx.no_intersection
        } 

        p := ray.e.add(ray.d.scale(t))
        n := surface.frame.z.scale(-1)
        frame:= gfx.frame_oz(p, n.as_direction())
        intersection := Intersection{frame, surface, ray.e.distance_to(p)}
        return intersection
    }

    return gfx.no_intersection
}
            

// Determines if given ray intersects any surface in the scene.
// If ray does not intersect anything, null is returned.
// Otherwise, details of first intersection are returned as an `Intersection` struct.
fn intersect_ray_scene(scene Scene, ray Ray) Intersection {
    mut closest := gfx.no_intersection  // type is Intersection
    for surface in scene.surfaces{
        intersection := intersect_ray_surface(surface, ray)
        if intersection == gfx.no_intersection{
            continue
        }
        if intersection.distance >= closest.distance{
            continue
        }
        else{
            closest = intersection    
        }
    }


    return closest  // return closest intersection
}

// Computes irradiance (as Color) from scene along ray
fn irradiance(scene Scene, ray Ray, depth1 int, depth2 int, ) Color {
    mut accum := scene.background_color
    intersection := intersect_ray_scene(scene, ray)
    if intersection == gfx.no_intersection{
        return accum
    }
    mat := intersection.surface.material
    accum = mat.kd.mult(scene.ambient_color)
    normal := intersection.frame.z.as_vector()
    
    for light in scene.lights{
        o := intersection.frame.o
        lr := light.kl.scale(1 / light.frame.o.vector_to(o).length_squared())
        light_dir := light.frame.o.vector_to(o).normalize()
        //shadow_ray := light.frame.o.ray_along(light_dir.as_direction())
        shadow_ray := o.ray_to(light.frame.o)
        shadow_intersection := intersect_ray_scene(scene, shadow_ray)
        if shadow_intersection != gfx.no_intersection && shadow_intersection.distance < intersection.distance && shadow_intersection.distance > ray.t_min{
            
            continue
        }
        
       // direct := accum
       
        cos_1 := normal.dot(light_dir)
        if cos_1 > 0{
            diffuse:= mat.kd.scale(cos_1).mult(Color{lr.r, lr.g, lr.b})
            accum = accum.add(diffuse)
            
        } 
        v := ray.d
        h := (light_dir.add(v.as_vector())).normalize()
        cos_2 := normal.dot(h)
        if cos_2 > 0{
            specular := mat.ks.scale(math.pow(cos_2,mat.n)).mult(Color{lr.r, lr.g, lr.b})
            accum = accum.add(specular)
        }
    }
    if mat.kr != gfx.black && depth1 > 0 {
  
        ref_dir := ray.d.scale(-1).add(normal.scale(2 * normal.dot(ray.d)))
        ref_ray := intersection.frame.o.ray_along(ref_dir.as_direction())
        ref_color := irradiance(scene, ref_ray, depth1 - 1, depth2)
        accum = accum.add(ref_color.mult(Color{mat.kr.r, mat.kr.g, mat.kr.b}))
    }

    if mat.kt != gfx.black && depth2 > 0{
            
        mut n := 1/ mat.ridx // air to material
        mut norm := intersection.frame.z.as_vector()
        mut c1 := ray.d.scale(-1).dot(norm)
        if c1 < 0{
            c1 = -c1
            n = mat.ridx // material to air
            norm = norm.scale(-1)
        }
        d := 1.0 - (n*n *(1.0-(c1*c1)))
        if d > 0{
            c2 := math.sqrt(d) 
            t := ray.d.scale(-n).sub(norm.scale((c1 * n + c2)))
            tray := intersection.frame.o.ray_along(t.as_direction())
            refract_c := irradiance(scene, tray, depth1, depth2 - 1)
            accum = accum.add(refract_c.mult(Color{mat.kt.r, mat.kt.g, mat.kt.b}))
        }

        }
         


    return accum
}

// Computes image of scene using basic Whitted raytracer.
fn raytrace(scene Scene) Image {
    mut image := gfx.Image.new(scene.camera.sensor.resolution)
    width:= scene.camera.sensor.resolution.width
    height:= scene.camera.sensor.resolution.height
    frame := scene.camera.frame
    samples := scene.camera.sensor.samples
    depth1 := 3
    depth2 := 3

    if samples == 1 {
        for y in 0.. height{    
            for x in 0.. width{
                u := (f64(x) + .5) / f64(width)
                v := 1.0 - (f64(y) + .5) / f64(height) 

                q := frame.o.add(frame.x.scale((u-0.5)*scene.camera.sensor.size.width).add(frame.y.scale((v-0.5)*scene.camera.sensor.size.height).sub(frame.z.scale(scene.camera.sensor.distance))))
                
                direction := frame.o.vector_to(q).normalize().as_direction()
                ray := frame.o.ray_along(direction)

                set_color := irradiance(scene, ray, depth1, depth2)
                image.set_xy(x, y, set_color)
            }

        }
    }
    if samples > 1 {
        for y in 0.. height{    
            for x in 0.. width{
                mut accum := Color{0.0,0.0,0.0}
                for i in 0..samples{
                    for j in 0..samples{
                        u := (f64(x) + (i + .5) / f64(samples)) / f64(width)
                        v := 1.0 - (f64(y) + (j + .5) / f64(samples)) / f64(height) 

                        q := frame.o.add(frame.x.scale((u-0.5)*scene.camera.sensor.size.width).add(frame.y.scale((v-0.5)*scene.camera.sensor.size.height).sub(frame.z.scale(scene.camera.sensor.distance))))
                    
                        direction := frame.o.vector_to(q).normalize().as_direction()
                        
                        ray := frame.o.ray_along(direction)


                        sample_color := irradiance(scene, ray, depth1, depth2)
                        accum.add_in(sample_color)
                        
                    }
                        
                }

                accum.scale_in(f64(1.0/f64(samples*samples)))
                image.set_xy(x, y, accum)
                
            }

        }
    }
    return image

}

fn main() {
    // Make sure images folder exists, because this is where all generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    for filename in scene_filenames {
        println('Rendering ${filename}...')
        scene := gfx.scene_from_file('scenes/${filename}.json')!
        image := raytrace(scene)
        image.save_png('output/${filename}.png')
    }

    println('Done!')
}
