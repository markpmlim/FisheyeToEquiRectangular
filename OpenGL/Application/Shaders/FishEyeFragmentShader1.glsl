// Fisheye to spherical conversion (aka equirectangular projection)
// Assumes the fisheye image is square, centered, and the circle fills the image.
// Output (spherical) image should have 2:1 aspect

#ifdef GL_ES
precision mediump float;
#endif

#if __VERSION__ >= 140
in vec2 texCoords;

out vec4 FragColor;

#else

varying vec2 texCoords;

#endif

uniform sampler2D fishEyeImage;
uniform vec2 u_resolution;  // Input image size (width, height)
uniform vec2 u_mouse;       // mouse position in screen pixels (unused)
uniform float u_time;       // Time in seconds since load (unused)
uniform float FOV;          // in degrees


#define iResolution u_resolution
#define iMouse      u_mouse
#define iTime       u_time

const float PI = 3.14159265359;

// Identical output for both fish2sphere functions
/*
 Convert to FishEye space.
 The ratio of the dimensions of the FishEye image is expected to be 1:1
 The ratio of the dimensions of the output image is 2:1
 The port of OpenGL GLSL of Paul Bourke's kernel function "fish2sphere".
 */
vec2 fish2sphere(vec2 destCoord) {
    vec2 pfish;
    float theta, phi, r;
    vec3 psph;
    
    float width = u_resolution.x;   // pass resolution of fisheye texture
    float height = u_resolution.y;  // Assumes width and height are equal
    
    // Polar angles
    // [0, input_image.width] --> [-0.5, 0.5]
    // [0, input_image.height] --> [-0.5, 0.5]
    // Range for longitude: 2 * π * [-0.5, 0.5] --> [-π, +π]
    // Range for  latitude:     π * [-0.5, 0.5] --> [-π/2, +π/2]
    // The width of the fisheye image is half that of the equirectangular image
    //  so we must multiply by 2 here.
    float longtitude = 2.0 * PI * (destCoord.x / width - 0.5);  // -π to π
    float latitude   =       PI * (destCoord.y / height - 0.5); // -π/2 to π/2
    
    // Vector in 3D space
    // Convert from polar coords to (x, y, z) vector
    psph.x = cos(latitude) * sin(longtitude);
    psph.y = cos(latitude) * cos(longtitude);
    psph.z = sin(latitude);
    
    // Calculate fisheye angle and radius
    theta = atan(psph.z, psph.x);
    // Don't multiply the value returned by atan() by 2
    phi = atan(sqrt(psph.x*psph.x + psph.z*psph.z),
               psph.y);
    
    // Compute the radius
    r = width * phi / radians(FOV);
    
    // Pixel in fisheye space.
    // The width and the height of the fisheye image are equal
    pfish.x = 0.5 * width + r * cos(theta);
    pfish.y = 0.5 * width + r * sin(theta);
    // However, pfish.x and pfish.y can take negative values.
    // They can also > width.
    return vec2(pfish.x, pfish.y);
}

// Gives the same output as fish2sphere.
// We modify the code slightly by swapping psph.y and psph.z
vec2 fish2sphere2(vec2 destCoord) {
    vec2 pfish;
    vec3 psph;

    //float FOV = 3.141592654;      // FOV of the fisheye, eg: 180 degrees
    float width = u_resolution.x;   // pass resolution of fisheye texture
    float height = u_resolution.y;
    
    // Polar angles
    // [0, input_image.width] --> [-0.5, 0.5]
    // [0, input_image.height] --> [-0.5, 0.5]
    // Range for longitude: 2 * π * [-0.5, 0.5] --> [-π, +π]
    // Range for  latitude:     π * [-0.5, 0.5] --> [-π/2, +π/2]
    // The width of the fisheye image is half that of the equirectangular image
    //  so we must multiply by 2 here.
    float longitude = 2 * PI * (destCoord.x / width - 0.5);     // -π to π
    float latitude  =     PI * (destCoord.y / height - 0.5);    // -π/2 to π/2
    
    // Vector in 3D space
    // Convert from polar coords to (x, y, z) vector
    psph.x = cos(latitude) * sin(longitude);
    psph.y = sin(latitude);
    psph.z = cos(latitude) * cos(longitude);

    // Calculate fisheye angle and radius
    float theta = atan(psph.y, psph.x);
    // Don't multiply the value returned by atan() by 2
    float phi = atan(sqrt(psph.x*psph.x + psph.y*psph.y),
                     psph.z);
    // Compute the radius
    float r = width * phi / radians(FOV);
    
    // Pixel in fisheye space
    pfish.x = 0.5 * width + r * cos(theta);
    pfish.y = 0.5 * width + r * sin(theta);
    // pfish.x and pfish.y can take negative values.
    // They can also be > the fisheye's texture width/height.

    return vec2(pfish.x, pfish.y);
}

/*
 The fragments are sent in the form of a rectangular grid. We don't
 need a double loop to process the colors of all fragments.
 The width of the output image is twice that of the input fisheye image.
 Their heights are equal.
 */
void main(void) {
    // x: [0, 1] ---> [0, input_image.width]
    // y: [0, 1] ---> [0, input_image.height]
    // Since we are passing the resolution of the fisheye image,
    //  u_resolution.x == u_resolution.y
    vec2 destCoord = texCoords * u_resolution;
    vec2 uv = fish2sphere(destCoord);
    // We must request OpenGL to set texture wrap to GL_CLAMP_TO_BORDER
    // Scale it to [0, 1.0]
    uv /= u_resolution;
#if __VERSION__ >= 140
    FragColor = texture(fishEyeImage, uv);
#else
    gl_FragColor = texture2D(fishEyeImage, uv);
#endif

}
