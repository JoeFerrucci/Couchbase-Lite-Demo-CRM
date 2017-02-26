//
//  UIImage+Tools.m
//
//
//  Created by Andrew on 12.03.13.
//  Copyright (c) 2013 Couchbase All rights reserved.
//

#import "UIImage+Tools.h"

@implementation UIImage (Tools)

- (UIImage*) squiredImage
{
    // Calculate Maximum of width/height
    CGFloat maxSize = MAX(self.size.height, self.size.width);
    
    // Create New Graphics Contenxt
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(maxSize, maxSize), NO, 2.0);

    // Set Fill Color
    [[UIColor blackColor] set];
    
    // Fill with color
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, maxSize, maxSize));
    
    // Drow image in center
    [self drawInRect:CGRectMake((maxSize-self.size.width) /2,
                                (maxSize-self.size.height)/2, self.size.width, self.size.height)];
    
    // Get UIImage from Context
    UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End The Context
    UIGraphicsEndImageContext();

    // Return:)
    return squareImage;
}

- (UIImage*) scaledSquaredImageToSize:(CGFloat)size {
    
    // Create Squired Image
    UIImage * squiredImage = [self squiredImage];
    
    // Create New Graphics Context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 2.0);
    
    // Draw image on it (scaled)
    [squiredImage drawInRect:CGRectMake(0, 0, size, size)];
    
    // Create UIImage from the context
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
   
    // End The Context
    UIGraphicsEndImageContext();
    
    // Return:)
    return scaledImage;
}

@end
