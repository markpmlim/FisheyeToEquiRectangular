// https://stackoverflow.com/questions/56986420/convert-a-fisheye-image-to-an-equirectangular-image-with-opencv4
// Fisheye to spherical conversion
// Assumes the fisheye image is square, centered, and the circle fills the image.
// Output image should have 1:1 aspect

#ifdef GL_ES
precision mediump float;
#endif

#if __VERSION__ >= 140
in vec2 texCoords;

out vec4 FragColor;

#else

in vec2 texCoords;

#endif

uniform sampler2D fishEyeImage;
uniform vec2 u_resolution;  // Input Image size (width, height)
uniform vec2 u_mouse;       // mouse position in screen pixels (unused)
uniform float u_time;       // Time in seconds since load (unused)
uniform float FOV;

#define iResolution u_resolution
#define iMouse      u_mouse
#define iTime       u_time

const float PI = 3.14159265359;

/*
 Convert to FishEye space.
 The ratio of the dimensions of the FishEye image is expected to be 1:1
 The ratio of the dimensions of the output image is 1:1
 */
vec2 mapToFisheyePointUV(vec2 inUV) {

    // [0, 1] --> [-0.5, 0.5] --> [-π/2, π/2]
    float longtitude = PI * (inUV.x - 0.5);
    float latitude   = PI * (inUV.y - 0.5);

    // Convert from spherical coords to Cartesian coords
    vec3 sphericalPoint;
    sphericalPoint.x = cos(latitude) * sin(longtitude);
    sphericalPoint.y = sin(latitude);
    sphericalPoint.z = cos(latitude) * cos(longtitude);

    // Range for theta: [-π, π]
    float theta = atan(sphericalPoint.y,
                       sphericalPoint.x);
    // Range for phi: [-π, π]
    // Don't multiply the value returned by atan() by 2
    float phi = atan(sqrt(pow(sphericalPoint.x,2) + pow(sphericalPoint.y,2)),
                     sphericalPoint.z);

    float r = u_resolution.x * phi / radians(FOV);

    // Range: [0.0, u_resolution.x]
    vec2 fisheyePoint;
    fisheyePoint.x = 0.5 * u_resolution.x + r * cos(theta);
    fisheyePoint.y = 0.5 * u_resolution.x + r * sin(theta);
    //fisheyePoint.y = 0.5 * u_resolution.y + r * sin(theta);

    // Scale it back to [0, 1]
    vec2 uv = fisheyePoint/u_resolution.x;

    return uv;
}

/*
 The fragments are sent in the form of a rectangular grid. We don't
 need a double loop to process the colors of all fragments.
 */
void main(void) {
    vec2 uv = mapToFisheyePointUV(texCoords);
    // We may have to request OpenGL to set texture wrap to GL_CLAMP_TO_BORDER
    #if __VERSION__ >= 140
        FragColor = texture(fishEyeImage, uv);
    #else
        gl_FragColor = texture2D(fishEyeImage, uv);
    #endif
}
