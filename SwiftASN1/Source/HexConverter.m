//
//  HexConverter.m
//  PeaceKeeper
//
//  Created by Rowland Smith on 11/22/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

#import "HexConverter.h"

@implementation HexConverter

+( NSData * ) hex2data:( NSString * ) hex {
    
    /*
    hex = [ hex stringByReplacingOccurrencesOfString:@" " withString:@"" ] ;
    hex = [ hex stringByReplacingOccurrencesOfString:@"\n" withString:@"" ] ;
    hex = [ hex stringByReplacingOccurrencesOfString:@"\r" withString:@"" ] ;
    hex = [ hex stringByReplacingOccurrencesOfString:@"\t" withString:@"" ] ;
    */
    
    const char *chars = [ hex UTF8String ] ;
    
    //int i = 0, len = hex.length;
    unsigned long i = 0, len = hex.length;
    
    NSMutableData *data = [ NSMutableData dataWithCapacity:len / 2 ] ;
    char byteChars[ 3 ] = { '\0','\0','\0' } ;
    unsigned long wholeByte ;
    
    while ( i < len ) {
        byteChars[ 0 ] = chars[ i++ ] ;
        byteChars[ 1 ] = chars[ i++ ] ;
        wholeByte = strtoul( byteChars, NULL, 16 ) ;
        [ data appendBytes:&wholeByte length:1 ] ;
    }
    
    return data ;
    
}

@end
