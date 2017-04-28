//
//  NSData+JFRBinaryInspection.h
//  SimpleTest
//
//  Created by Adam Kaplan on 4/15/15.
//

#import <Foundation/Foundation.h>

@interface NSData (JFRBinaryInspection)

/** Returns a bit-string representation of this data, formatted as 1s and 0s grouped by 8-bits. */
- (NSString *)binaryString;

@end