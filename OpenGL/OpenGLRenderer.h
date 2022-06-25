/*

 OpenGLRenderer
 FisheyeToEquiRectangular

 Created by Mark Lim Pak Mun on 24/06/2022.
 Ported from Apple's MigratingOpenGLCodeToMetal

*/

#import <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKTextureLoader.h>
#import "OpenGLHeaders.h"

static const CGSize AAPLInteropTextureSize = {1024, 1024};

@interface OpenGLRenderer : NSObject {
}

- (instancetype)initWithDefaultFBOName:(GLuint)defaultFBOName;

- (void)draw;

- (void)resize:(CGSize)size;

@property CGPoint mouseCoords;

@end
