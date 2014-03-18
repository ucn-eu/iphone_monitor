//
//  ProcessLogger.h
//  appmon
//
//  Created by Tom Lodge on 03/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import "Util.h"

@interface ProcessLogger : NSObject
+(ProcessLogger *) logger;

-(void) logToServer;
-(NSDictionary *) sample;
-(id) initWithURL:(NSString*) url logInterval: (float) interval sampleInterval: (float) sampleInterval;

@property(nonatomic, assign) long lastLog;
@property(nonatomic, assign) long lastSnapshot;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;
@end
