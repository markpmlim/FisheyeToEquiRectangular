## Convert a Circular FishEye image to an EquiRectangular image


This project attempts to convert circular fisheye images to 2:1 equirectangular images or 1:1 square images.

<br />
<br />
<br />

The mathematics of the conversion is simple but implementation in glsl can lead to unexpected output.

In general, when one needs to convert a 2D input image from one format into another, a 3D vector must be generated using the texture coordinates of the 2D output texture, which in OpenGL, the range is [0.0, 1.0] for both the u-axis and v-axis. The 3D vector is then used to generate a pair of texture coordinates which is then used to access the input image.

<br />
<br />

Refer to the source code of the fragment shader *FishEyeFragmentShader.glsl*.

The texture coordinates of the current fragment being processed is converted to a pair of Cartesian coordinates by multiplying its value with the pixel width of the input (fisheye) image. The resulting value is passed to the function *fish2sphere*  which is a GLSL port of Paul Bourke's function of the same name.

The first step taken by this function is to map the pair of pixel coordinates received as a parameter to a point on a rectangle with a range of [-π, +π] for its horizontal axis and  [-π/2, +π/2] for its vertical axis. Then, it converts the longitudinal and latitudinal values of that point to a 3D point on a unit sphere.

The spherical coordinates are used to calculate the following fisheye angles:

```glsl

    float theta = atan(psph.y, psph.x);
    float phi = atan(sqrt(psph.x*psph.x + psph.y*psph.y),
                     psph.z);

```


Notice that in the glsl implementation, we don't multiply the value of *phi* by 2 unlike the information given in Paul Bourke's diagram (see below).

The values of the 2 angles are then used to calculate the radius, *r*.

```glsl

    float r = width * phi / radians(FOV);

```



Finally, the value of the point passed in as a parameter to the function is expressed in the pixel coordinate system of the fisheye image.

 ```glsl

    pfish.x = 0.5 * width + r * cos(theta);
    pfish.y = 0.5 * width + r * sin(theta);

```

BTW, we could re-write the 2 equations above as:


 ```glsl
 
    pfish = vec2(0.5 * width + r * cos(theta)
                 0.5 * width + r * sin(theta));


```


The expected output of the equirectangular image is:

![](ExpectedOutput.png)


To get a 1:1 output, use *FishEyeFragmentShader1.glsl*. 


![](ExpectedOutput1.png)


For this case, the range of the longitudinal values is the same as that of its latitudinal values. You have to edit two UI widgets using XCode's Interface Builder module so that the ratios of the window and view sizes are 1:1 since their display rectangles had been set to the ratio 2:1. Otherwise, the output looks like this:


![](ExpectedOutput2.png)

The fragment shader *FishEyeFragmentShader2.glsl* is a variation of *FishEyeFragmentShader1.glsl*. The fisheye's image resolution is not used in the projection.


To get the 2:1 equirectangular output without artifacts, run the demo with the fragment shader *FishEyeFragmentShader3.glsl*.  Instead of projecting the circular fisheye image to the entire 2:1 equirectangular region, we map it to the central part of the latter.  It is not necessary to set texture wrap to GL_CLAMP_TO_BORDER.


![](ExpectedOutput3.png)


**Notes**: To save an image from a generated equirectangular texture, scaling might be required because OpenGL's texture coordinate system is always in the ratio 1:1.


The code for the fragment shader *FishEyeFragmentShader.glsl* was originally derived from the diagram below lifted from Paul Bourke's site:


![](diagram_s.png)



The value of *r* must be calculated as follows:

```glsl

    float phi = atan(sqrt(p.x*p.x + p.y*p.y),
                     p.z);

    float width = 2.0;

    float r = width * phi/radians(FOV);


```


because the following equations in the diagram:


```glsl

     x = r * cos(theta);
     y = r * sin(theta);


```

does not work. You wouldn't get any output.

Those 2 equations can be expressed in glsl as:

```glsl

     uv = vec2(r * cos(theta), r * sin(theta));

```

<br />
<br />
<br />

*Web links:*

http://paulbourke.net/dome/dualfish2sphere/

http://paulbourke.net/dome/fish2/


 
