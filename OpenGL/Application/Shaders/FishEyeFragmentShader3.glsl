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

    // We must multiply by 2
    // Range of inUV.x: [0.25, 0.75]
    // Range of inUV.y: [0.0, 1.0]
    // [0.25, 0.75] --> [-0.25, 0.25] --> [-π/2, π/2]
    float longtitude = 2 * PI * (inUV.x - 0.5);
    // [0.0, 1.0] --> [-0.5, 0.5] --> [-π/2, π/2]
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

    // Scale it back to [0, 1]
    vec2 uv = fisheyePoint/u_resolution.x;

    return uv;
}

/*
 The fragments are sent in the form of a rectangular grid. We don't
 need a double loop to process the colors of all fragments.

 The single fisheye image is mapped to an equirectangular plane.
 "texCoords" is the interpolated texture coordinates of the current
  fragment of the output image which has a resolution of 2:1
 */
void main(void) {
    vec2 uv = vec2(0);
    // The unwarped fisheye image will be projected at the centre of the
    //  the equirectangular image. The rest of the equirectangular image
    //  will be the background color which is black.
    if (texCoords.x >= 0.25 && texCoords.x <= 0.75)
        uv = mapToFisheyePointUV(texCoords);
    // No need to set texture wrap to GL_CLAMP_TO_BORDER
    #if __VERSION__ >= 140
        FragColor = texture(fishEyeImage, uv);
    #else
        gl_FragColor = texture2D(fishEyeImage, uv);
    #endif
}
