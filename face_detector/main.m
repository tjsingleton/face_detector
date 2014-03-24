//
//  main.m
//  face_detector
//
//  Created by Julián Romero on 10/03/14.
//  Copyright (c) 2014 Julián Romero. All rights reserved.
//
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

//#define FACE_DETECTOR_OUTPUT_DIRECTORY @"/Volumes/mem/face_detector"
#ifndef FACE_DETECTOR_OUTPUT_DIRECTORY
#define FACE_DETECTOR_OUTPUT_DIRECTORY [NSString stringWithFormat:@"%@/Desktop/face_detector", NSHomeDirectory()]
#endif

#define FACE_BOX_COLOR      [NSColor magentaColor]
#define LEFT_EYE_BOX_COLOR  [NSColor cyanColor]
#define RIGHT_EYE_BOX_COLOR [NSColor cyanColor]
#define MOUTH_BOX_COLOR     [NSColor redColor]

char *to_s(NSString *string){return [string cStringUsingEncoding:NSUTF8StringEncoding];}

void draw_faces_on_context(CGContextRef c, NSArray *faces)
{
    /* FIXME: take into account the face angle */
    for (CIFaceFeature *face in faces) {
        CGRect bounds = face.bounds;
        [FACE_BOX_COLOR set];
        CGContextStrokeRect(c, CGRectMake(bounds.origin.x, bounds.origin.y , bounds.size.width , bounds.size.height ));

        if (face.hasLeftEyePosition) {
            CGPoint leftEyePosition = face.leftEyePosition;
            [LEFT_EYE_BOX_COLOR set];
            CGContextStrokeRect(c, CGRectMake(leftEyePosition.x - 16.0, leftEyePosition.y - 8.0, 32.0, 16.0));
        }

        if (face.hasRightEyePosition) {
            CGPoint rightEyePosition = face.rightEyePosition;
            [RIGHT_EYE_BOX_COLOR set];
            CGContextStrokeRect(c, CGRectMake(rightEyePosition.x - 16.0, rightEyePosition.y - 8.0, 32.0, 16.0));
        }

        if (face.hasMouthPosition) {
            CGPoint mouthPosition = face.mouthPosition;
            [MOUTH_BOX_COLOR set];
            CGContextStrokeEllipseInRect(c, CGRectMake(mouthPosition.x - 20.0, mouthPosition.y - 10.0, 40.0, 20.0));
        }
    }
}

NSImage * add_faces_to_image(NSImage * image,  NSArray * faces)
{
    NSImage * output = nil;
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGRect imageRect = CGRectMake(0, 0, width, height);
   	output = [[NSImage alloc] initWithSize:(NSSize){width, height}];
	[output lockFocus];
    {
        CGImageRef cgImage = [image CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];
        CGContextRef imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextDrawImage(imageContext, *(CGRect*)&imageRect, cgImage);
        draw_faces_on_context(imageContext, faces);
        CGContextSetFillColorWithColor(imageContext, [NSColor greenColor].CGColor);
        CGContextFillRect(imageContext, CGRectMake(0, 0, 5, 5));
    }
	[output unlockFocus];
    return output;
}

NSBitmapImageRep* bitmapImageRep(NSImage *image)
{
	NSArray *list=[image representations];
	NSImageRep	*currentRepresentation	= nil;
	for(currentRepresentation in list) {
        if([currentRepresentation isKindOfClass:[NSBitmapImageRep class]]) {
			return (NSBitmapImageRep *)currentRepresentation;
		}
	}
	NSData *data = [image TIFFRepresentation];
	if (data) {
        return [[NSBitmapImageRep alloc] initWithData:data];
    }
	return nil;
}

void save_to_path(NSImage * image, NSString* path, BOOL isJpeg)
{
	NSBitmapImageRep *bitmapRep = bitmapImageRep(image);
	NSData *data = [bitmapRep representationUsingType: isJpeg ? NSJPEGFileType : NSPNGFileType properties: nil];
	[data writeToFile:path atomically: NO];
}

int main(int argc, const char * argv[])
{
    if (argc < 2) {
        printf("Usage:\n%s /path/to/image\n", argv[0]);
        return 1;
    }

    @autoreleasepool {

        CIDetector *faceDetector;
        NSArray *faces;

        faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, nil]];

        NSString *imagePath = [NSString stringWithUTF8String:argv[1]];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];

        /* create CIImage from bitmap */
        NSBitmapImageRep * bitmap = bitmapImageRep(image);
        CIImage * ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmap];

        /* detect the faces */
        faces = [faceDetector featuresInImage:ciImage];
        
        for (CIFaceFeature *face in faces) {
            CGFloat height = image.size.height;
            CGRect bounds = face.bounds;
            printf("(%d,%d),(%d,%d)\n", (int)bounds.origin.x, (int) bounds.origin.y, (int) bounds.size.width, (int) bounds.size.height);
        }
    }
    return 0;
}
