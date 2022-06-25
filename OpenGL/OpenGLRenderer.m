/*

 OpenGLRenderer
 FisheyeToEquiRectangular

 Created by Mark Lim Pak Mun on 24/06/2022.
 Modified from Apple's MigratingOpenGLCodeToMetal

*/

#import "OpenGLRenderer.h"
#import "AAPLMathUtilities.h"
#import <Foundation/Foundation.h>
#import <simd/simd.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

@implementation OpenGLRenderer {
    GLuint _defaultFBOName;
    CGSize _viewSize;
    GLuint _glslProgram;
    GLint _resolutionLoc;
    GLint _mouseLoc;
    GLint _timeLoc;
    GLint _fovLoc;
    GLuint _fishEyeTextureID;

    CGSize _tex0Resolution;
    GLuint _triangleVAO;
    GLfloat _currentTime;

    matrix_float4x4 _projectionMatrix;
}

- (instancetype)initWithDefaultFBOName:(GLuint)defaultFBOName
{
    self = [super init];
    if(self) {
        NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));

        // Build all of your objects and setup initial state here.
        _defaultFBOName = defaultFBOName;
        glGenVertexArrays (1, &_triangleVAO);    // Required
        glBindVertexArray(_triangleVAO);

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *vertexSourceURL = [mainBundle URLForResource:@"SimpleVertexShader"
                                              withExtension:@"glsl"];
        NSURL *fragmentSourceURL = [mainBundle URLForResource:@"FishEyeFragmentShader1"
                                                withExtension:@"glsl"];
        _glslProgram = [OpenGLRenderer buildProgramWithVertexSourceURL:vertexSourceURL
                                                 withFragmentSourceURL:fragmentSourceURL];
        //NSLog(@"%@", fragmentSourceURL);
        printf("%u\n", _glslProgram);
        _resolutionLoc = glGetUniformLocation(_glslProgram, "u_resolution");
        _mouseLoc = glGetUniformLocation(_glslProgram, "u_mouse");
        _timeLoc = glGetUniformLocation(_glslProgram, "u_time");
        _fovLoc = glGetUniformLocation(_glslProgram, "FOV");
        //printf("%d %d %d\n", _resolutionLoc, _mouseLoc, _timeLoc);
        _fishEyeTextureID = [self textureWithContentsOfFile:@"TestImage.jpg"
                                                 resolution:&_tex0Resolution
                                                      isHDR:NO];
        printf("%f %f\n", _tex0Resolution.width, _tex0Resolution.height);
        glBindVertexArray(0);
    }

    return self;
}

- (void) dealloc {
    glDeleteProgram(_glslProgram);
    glDeleteVertexArrays(1, &_triangleVAO);
}


// We have set the view port's resolution as 2:1
- (void)resize:(CGSize)size
{
    // Handle the resize of the draw rectangle. In particular, update the perspective projection matrix
    // with a new aspect ratio because the view orientation, layout, or size has changed.
    _viewSize = size;
    float aspect = (float)size.width / size.height;
    printf("%f %f\n", _viewSize.width, _viewSize.height);
    // Unused
    _projectionMatrix = matrix_perspective_right_hand_gl(65.0f * (M_PI / 180.0f),
                                                         aspect,
                                                         1.0f, 5000.0);
}

// The fisheye image's resolution is 1:1 (square)
- (GLuint) textureWithContentsOfFile:(NSString *)name
                          resolution:(CGSize *)size
                               isHDR:(BOOL)isHDR
{
    GLuint textureID = 0;

    NSBundle *mainBundle = [NSBundle mainBundle];
    if (isHDR == YES) {
        NSArray<NSString *> *subStrings = [name componentsSeparatedByString:@"."];
        NSString *path = [mainBundle pathForResource:subStrings[0]
                                              ofType:subStrings[1]];
        GLint width = 0;
        GLint height = 0;
        GLint numComponents = 0;
        stbi_set_flip_vertically_on_load(false);
        GLfloat *data = nil;
        data = stbi_loadf([path UTF8String],
                          &width, &height, &numComponents, 0);
        if (data) {
            glGenTextures(1, &textureID);
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_RGB16F,
                         width, height,
                         0,
                         GL_RGB,
                         GL_FLOAT,
                         data);

            // Ask OpenGL to set texture wrap to GL_CLAMP_TO_BORDER
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            stbi_image_free(data);
        }
        else {
            printf("");
            exit(1);
        }
    }
    else {
        NSArray<NSString *> *subStrings = [name componentsSeparatedByString:@"."];

        NSURL* url = [mainBundle URLForResource: subStrings[0]
                                  withExtension: subStrings[1]];
        NSDictionary *loaderOptions = @{
            GLKTextureLoaderOriginBottomLeft : @YES,
        };
        NSError *error = nil;
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfURL:url
                                                                         options:loaderOptions
                                                                           error:&error];
        if (error != nil) {
            NSLog(@"%@: error encountered reading files", error);
            exit(2);
        }
        // Ask OpenGL to set texture wrap to GL_CLAMP_TO_BORDER
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        //NSLog(@"%@", textureInfo);
        textureID = textureInfo.name;
        size->width = textureInfo.width;
        size->height = textureInfo.height;
    }
    return textureID;
}

- (void) updateTime {
    _currentTime += 1/60;
}

- (void)draw {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  // Bind the quad vertex array object.
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glViewport(0, 0,
               _viewSize.width, _viewSize.height);
    glBindVertexArray(_triangleVAO);
    glUseProgram(_glslProgram);
    glUniform1f(_timeLoc, _currentTime);
    glUniform2f(_mouseLoc, _mouseCoords.x, _mouseCoords.y);
    // Use FishEyeFragmentShader1.glsl to get an output
    //  with the dimensions 2:1
    
    // Use FishEyeFragmentShader2.glsl to get an output
    //  with the dimensions 1:1
    // Pass the dimensions of the fisheye image.
    glUniform2f(_resolutionLoc,
                _tex0Resolution.width, _tex0Resolution.height);
    glUniform1f(_fovLoc, 180);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _fishEyeTextureID);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glUseProgram(0);
    glBindVertexArray(0);
} // draw


+ (GLuint)buildProgramWithVertexSourceURL:(NSURL*)vertexSourceURL
                    withFragmentSourceURL:(NSURL*)fragmentSourceURL {

    NSError *error;

    NSString *vertSourceString = [[NSString alloc] initWithContentsOfURL:vertexSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(vertSourceString, @"Could not load vertex shader source, error: %@.", error);

    NSString *fragSourceString = [[NSString alloc] initWithContentsOfURL:fragmentSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(fragSourceString, @"Could not load fragment shader source, error: %@.", error);

    // Prepend the #version definition to the vertex and fragment shaders.
    float  glLanguageVersion;

#if TARGET_IOS
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif

    // `GL_SHADING_LANGUAGE_VERSION` returns the standard version form with decimals, but the
    //  GLSL version preprocessor directive simply uses integers (e.g. 1.10 should be 110 and 1.40
    //  should be 140). You multiply the floating point number by 100 to get a proper version number
    //  for the GLSL preprocessor directive.
    GLuint version = 100 * glLanguageVersion;

    NSString *versionString = [[NSString alloc] initWithFormat:@"#version %d", version];
#if TARGET_IOS
    if ([[EAGLContext currentContext] API] == kEAGLRenderingAPIOpenGLES3)
        versionString = [versionString stringByAppendingString:@" es"];
#endif

    vertSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, vertSourceString];
    fragSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, fragSourceString];

    GLuint prgName;

    GLint logLength, status;

    // Create a GLSL program object.
    prgName = glCreateProgram();

    /*
     * Specify and compile a vertex shader.
     */

    GLchar *vertexSourceCString = (GLchar*)vertSourceString.UTF8String;
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const GLchar **)&(vertexSourceCString), NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);

    if (logLength > 0) {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vertex shader compile log:\n%s.\n", log);
        free(log);
    }

    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);

    NSAssert(status, @"Failed to compile the vertex shader:\n%s.\n", vertexSourceCString);

    // Attach the vertex shader to the program.
    glAttachShader(prgName, vertexShader);

    // Delete the vertex shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(vertexShader);

    /*
     * Specify and compile a fragment shader.
     */

    GLchar *fragSourceCString =  (GLchar*)fragSourceString.UTF8String;
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, (const GLchar **)&(fragSourceCString), NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Fragment shader compile log:\n%s.\n", log);
        free(log);
    }

    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);

    NSAssert(status, @"Failed to compile the fragment shader:\n%s.", fragSourceCString);

    // Attach the fragment shader to the program.
    glAttachShader(prgName, fragShader);

    // Delete the fragment shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(fragShader);

    /*
     * Link the program.
     */

    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_LINK_STATUS, &status);
    NSAssert(status, @"Failed to link program.");
    if (status == 0) {
        glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetProgramInfoLog(prgName, logLength, &logLength, log);
            NSLog(@"Program link log:\n%s.\n", log);
            free(log);
        }
    }

    // Added code
    // Call the 2 functions below if VAOs have been bound prior to creating the shader program
    // iOS will not complain if VAOs have NOT been bound.
    glValidateProgram(prgName);
    glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
    NSAssert(status, @"Failed to validate program.");

    if (status == 0) {
        fprintf(stderr,"Program cannot run with current OpenGL State\n");
        glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetProgramInfoLog(prgName, logLength, &logLength, log);
            NSLog(@"Program validate log:\n%s\n", log);
            free(log);
        }
    }

    //GLint samplerLoc = glGetUniformLocation(prgName, "baseColorMap");

    //NSAssert(samplerLoc >= 0, @"No uniform location found from `baseColorMap`.");

    //glUseProgram(prgName);

    // Indicate that the diffuse texture will be bound to texture unit 0.
   // glUniform1i(samplerLoc, AAPLTextureIndexBaseColor);

    GetGLError();

    return prgName;
}

@end
