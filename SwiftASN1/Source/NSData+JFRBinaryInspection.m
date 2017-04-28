//
//  NSData+JFRBinaryInspection.m
//  Jetfire
//
//  Created by Adam Kaplan on 4/15/15.
//

#import "NSData+JFRBinaryInspection.h"

@implementation NSData (JFRBinaryInspection)

- (NSString *)binaryString {
    static const unsigned char mask = 0x01;
    
    NSMutableString *str = [NSMutableString stringWithString:
                            @"0          1          2           3\n"
                            @"01234567 89012345 67890123 45678901\n"
                            @"-----------------------------------\n"];
    NSUInteger length = self.length;
    const unsigned char* bytes = self.bytes;
    
    for (NSUInteger offset = 0; offset < length; offset++) {
        
        if (offset > 0) {
            if (offset % 4 == 0) {
                [str appendString:@"\n"];
            }
            else {
                [str appendString:@" "];
            }
        }

        // TODO: Convert to use ranges - C-style 'for' is deprecated. -rds
        //
        for (char bit = 7; bit >= 0; bit--) {
            
            if ((mask << bit) & *(bytes+offset)) {
                [str appendString:@"1"];
            }
            else {
                [str appendString:@"0"];
            }
        }
    }
    
    return [str copy];
}

@end
