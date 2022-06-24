/*

https://stackoverflow.com/questions/46883320/conversion-from-dual-fisheye-coordinates-to-equirectangular-coordinates

You are building the equirectangular image, so I would suggest you to use the inverse mapping.

Start with pixel locations in the target image you are painting. Convert the 2D location to longitude/latitude.
Then convert that to a 3D point on the surface of the unit sphere.
Then convert from the 3D point to a location in the 2D fisheye source image.
In Paul Bourke page, you would start with the bottom equation, then the rightmost one, then the topmost one.

Use landmark points like 90° long 0° lat, to verify the results make sense at each step.

The final result should be a location in the source fisheye image in the [-1..+1] range. Remap to pixel or to UV as needed.
Since the source is split in two eye images you will also need a mapping from target (equirect) longitudes to the
correct source sub-image.

*/
#if __VERSION__ >= 140

in vec2 texCoords;

out vec4 FragCoord;

#else

varying vec2 texCoords;

#endif

uniform sampler2D fishEyeImage;
uniform float FOV;
uniform vec2 u_resolution;  // Canvas size (width, height)

const float PI = 3.14159265359;

// incoming uv are the texture coords of a point on the equirectangular image.
void main() {
    // Range of incoming texcoords: [0.0, 1.0]
    vec2 uv = texCoords;

    // Range of longitude: [-π, π]
    // Range of  latitude: [-π/2, π/2]
    float longitude = 2 * PI * (uv.x - 0.5);
    float latitude =      PI * (uv.y - 0.5);

    vec3 p = vec3(cos(latitude) * sin(longitude),
                  sin(latitude),
                  cos(latitude) * cos(longitude));

    // Range for theta: [-π, π]
    float theta = atan(p.y, p.x);
    // Almost identical to the code for single lens fisheye
    // Range for r: is it [-π, π]???
    float phi = atan(sqrt(p.x*p.x + p.y*p.y),
                     p.z);

    // Any arbitrary positive number as long as its value does not exceed
    //  the limits of a floating point number
    float width = 2.0;

    float r = width * phi/radians(FOV);

    /*
     the original code:

     uv = vec2(r * cos(theta), r * sin(theta));

     does not work.

     */
    uv = vec2(0.5 * width + r * cos(theta),
              0.5 * width + r * sin(theta));

    uv /= width;
#if __VERSION__ >= 140
    FragCoord = texture(fishEyeImage, uv);
#else
    gl_FragCoord = texture2D(fishEyeImage, uv);
#endif
}
