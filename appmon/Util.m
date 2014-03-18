//
//  Util.m
//  appmon
//
//  Created by Tom Lodge on 07/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "Util.h"

@implementation Util

+(NSString *) tsToString:(long) seconds{
    NSString* running;
    
    if (seconds < 60){ //seconds
        running = [NSString stringWithFormat:@"%lu sec", seconds];
    }else if (seconds < 60*60){// minutes
        running = [NSString stringWithFormat:@"%lu min", seconds / 60];
    }else if (seconds < 60 * 60 * 24){ //hours
        running = [NSString stringWithFormat:@"%lu hr", seconds / (60*60)];
    }
    else{ //days
        running = [NSString stringWithFormat:@"%lu days", seconds / (60*60*24)];
    }
    return running;
}

+(BOOL) amInsideTimeRange:(NSString *) from to: (NSString*) to{
    
    @try{
        NSArray *frmcmp = [from componentsSeparatedByString:@":"];
        NSArray *tocmp  = [to componentsSeparatedByString:@":"];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:[NSDate date]];

        NSInteger fromhr   = [frmcmp[0] integerValue];
        NSInteger frommin  = [frmcmp[1] integerValue];
        NSInteger tohr     = [tocmp[0] integerValue];
        NSInteger tomin    = [tocmp[1] integerValue];
        
        NSInteger nowhr  = [components hour];
        NSInteger nowmin = [components minute];
        
        if (fromhr == tohr && frommin == tomin){
            return YES;
        }
        //if the to time is greater than the from time
        if (fromhr < tohr || ((fromhr == tohr) && (frommin < tomin))){
            if (nowhr > fromhr && nowhr < tohr){
                return YES; 
            }
            if (nowhr == fromhr){
                if (nowmin > frommin){
                    if (tohr > nowhr){
                        return YES;
                    }
                    if (nowhr == tohr){
                        return (nowmin > frommin && nowmin < tomin);
                    }
                }
            }
            return NO;
        }
        else{
            if (nowhr < fromhr && nowhr > tohr){
                return NO;
            }
            if (nowhr == fromhr){
                return !(nowmin > tomin && nowmin < frommin);
            }
            return YES;
        }
    }
    @catch (NSException *exception) {
        return NO;
    }
    return NO;
}

@end
