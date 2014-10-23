//
//  ProcessLogger.m
//  appmon
//
//  Created by Tom Lodge on 03/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "ProcessLogger.h"
#include <ifaddrs.h>
#include <net/if.h>
#include <mach/mach_time.h>

#import <sys/sysctl.h>
#import <dlfcn.h>

#define SBSERVPATH "/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices"

@interface ProcessLogger ()
@property(nonatomic, assign) int logInterval;
@property(nonatomic, assign) int sampleInterval;

@end

@implementation ProcessLogger

@synthesize lastLog;
@synthesize lastSnapshot;
@synthesize from;
@synthesize to;

+(ProcessLogger *) logger{
    static ProcessLogger* logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[ProcessLogger alloc] init];
    });
    return logger;
}

-(id) initWithSettings: (float) logInterval sampleInterval:(float) sampleInterval{
    
    self = [super init];
    self.logInterval = (int) (logInterval * 60.0 * 60.0);  //convert from hours to sec
    self.sampleInterval = (int) (sampleInterval * 60.0);   //convert from min to sec
    
    NSLog(@"Sample interval is %d seconds", self.sampleInterval);
    NSLog(@"Log interval is %d seconds", self.logInterval);
    
    NSNumber *ls = [[NSUserDefaults standardUserDefaults] objectForKey:@"last_snapshot"];
    
    NSLog(@"last snapshot set to %@", ls);
    
    if (ls){
        self.lastSnapshot = [ls longValue];
    }else{
        self.lastSnapshot = 0;
    }
    
    //read in last sample from file
    
    NSNumber *ll = [[NSUserDefaults standardUserDefaults] objectForKey:@"last_log"];
    
    if (ll){
        self.lastLog = [ll longValue];
    }else{
        self.lastLog = 0;
    }
    
    NSLog(@"last log is set as %lu", self.lastLog);
    NSLog(@"last snapshot is set as %lu", self.lastSnapshot);
    
    //get the ranges for which we are NOT to sample/log data
    NSString* timerange = [[NSUserDefaults standardUserDefaults] objectForKey:@"logging_off"];
    NSArray *components = [timerange componentsSeparatedByString:@" "];
    self.from = components[0];
    self.to   = components[1];
    return self;
}

-(mach_port_t *) getSpringBoardPort{
    mach_port_t *port;
    void *lib = dlopen(SBSERVPATH, RTLD_LAZY);
    int (*SBSSpringBoardServerPort)() =
    dlsym(lib, "SBSSpringBoardServerPort");
    port = (mach_port_t *)SBSSpringBoardServerPort();
    dlclose(lib);
    return port;
}

-(NSString *) foregroundapp{
   
    mach_port_t * port = [self getSpringBoardPort];
    // open springboard lib
    void *lib = dlopen(SBSERVPATH, RTLD_LAZY);
    
    // retrieve function SBFrontmostApplicationDisplayIdentifier
    void *(*SBFrontmostApplicationDisplayIdentifier)(mach_port_t *port, char *result) =
    dlsym(lib, "SBFrontmostApplicationDisplayIdentifier");
    
    // reserve memory for name
    char appId[256];
    memset(appId, 0, sizeof(appId));
    
    // retrieve front app name
    SBFrontmostApplicationDisplayIdentifier(port, appId);
    
    // close dynlib
    dlclose(lib);
    
    NSArray* components = [[NSString stringWithCString:appId encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"."];
    return [components lastObject];
}

-(NSArray *) processes{
   
    NSString *foregroundapp = [self foregroundapp];
    long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
   
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        
        size += size / 10;
        newprocess = realloc(process, size);
        
        if (!newprocess){
            
            if (process){
                free(process);
            }
            
            return nil;
        }
        
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
        
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0){
        
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            
            if (nprocess){
                
                NSMutableArray * array = [[NSMutableArray alloc] init];
                
                for (int i = nprocess - 1; i >= 0; i--){
                    
                   
                    NSString *name = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    
                    int fflag = [name isEqualToString:foregroundapp] ? 1: 0;
                    
                    NSNumber *starttime = [NSNumber numberWithLong: process[i].kp_proc.p_un.__p_starttime.tv_sec];
                    
                    NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithLong:now], name, starttime, [NSNumber numberWithInt:fflag]] forKeys:@[@"ts", @"name", @"starttime", @"foreground"]];
                   
                    [array addObject:dict];
                }
                
                free(process);
                NSSortDescriptor* stime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:NO];
            
                
                [array sortUsingDescriptors:[NSArray arrayWithObject: stime]];
                return array;
            }
        }
    }
    return nil;
}


- (int)uptime
{
    struct timeval boottime;
    
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    
    size_t size = sizeof(boottime);
    
    time_t now;
    
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    return (int)uptime;
}

- (NSArray *)counters
{
    long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
    
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    unsigned long WiFiSent = 0;
    unsigned long WiFiReceived = 0;
    unsigned long WWANSent = 0;
    unsigned long WWANReceived = 0;
    
    NSString *name;
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent+=networkStatisc->ifi_obytes;
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                }
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent+=networkStatisc->ifi_obytes;
                    WWANReceived+=networkStatisc->ifi_ibytes;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    const int kMB = 1024*1024;
    
    return [NSArray arrayWithObjects: [NSNumber numberWithLong:now], [NSNumber numberWithLong:WiFiSent / kMB], [NSNumber numberWithLong:WiFiReceived/kMB],[NSNumber numberWithLong:WWANSent/kMB],[NSNumber numberWithLong:WWANReceived/kMB], nil];
}

-(NSDictionary *) sample{
    
    NSDictionary* datadict = [self collectData];
    
    long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
    
    if ((now - self.lastLog) > self.logInterval){
        NSLog(@"attempting to log to server!");
        [self logToServer];
    }
    else if ((now - self.lastSnapshot) > self.sampleInterval){
        NSLog(@"writing a snapshot to file!");
        [self snapshot:datadict];
    }
    return datadict;
}

-(NSDictionary *) collectData{
    
    NSNumber* ts = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSArray *myprocesses    = [self processes];
    NSArray *counters   = [[ProcessLogger logger] counters];
    
    NSDictionary *network   = [NSDictionary dictionaryWithObjects:@[counters[0], counters[1], counters[2], counters[3], counters[4]] forKeys:@[@"ts", @"wifiup", @"wifidown", @"cellup", @"celldown"]];
    
    NSString* uptime        = [Util tsToString:[[ProcessLogger logger] uptime]];
    NSString* battery       = [NSString stringWithFormat:@"%.f", (float)[[UIDevice currentDevice] batteryLevel]];
    
    NSDictionary *datadict = [NSDictionary dictionaryWithObjects:@[ts,myprocesses,network,uptime,battery] forKeys:@[@"ts", @"processes", @"network", @"uptime", @"battery"]];
    
    return datadict;
}


-(void) snapshot: (NSDictionary*) datadict{
    
    if ([Util amInsideTimeRange:self.from to:self.to]){
        NSLog(@"not snapshotting as inside quiet time!");
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:datadict options:0 error:nil];

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self logToFile:jsonString];
    
    self.lastSnapshot = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
    
    NSLog(@"done a file snapshot, so setting last snapshot to %lu", self.lastSnapshot);
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.lastSnapshot] forKey:@"last_snapshot"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(void) logToServer{
    
    if ([Util amInsideTimeRange:self.from to:self.to]){
        NSLog(@"not logging to server as inside quiet time!");
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@/samples.json", [self documentsDirectory]];
    
   
    NSString *content = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    
   
    NSDictionary *samples = nil;
    NSError *error = nil;
    
    if (content == nil){
        samples = [self collectData];
    }else{
       
        content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@","];
       
        NSString *jsoncontent = [NSString stringWithFormat:@"[%@]",content];
        
        samples = [NSJSONSerialization JSONObjectWithData:[jsoncontent dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error:&error];
       
    }
    
   
    NSData *processes = [NSJSONSerialization dataWithJSONObject:samples options:0 error:&error];
   
    //get the latest server url, incase has changed!!
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    [request setURL:[NSURL URLWithString: [self serverurl]]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", [processes length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:processes];
    
    NSHTTPURLResponse* urlResponse = nil;
  
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse: &urlResponse error:&error];
    
    if (response != nil){
        if(error == nil) {
            self.lastLog= [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.lastLog] forKey:@"last_log"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *result = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            
            NSError* e;
           
            if (result){
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData: [result dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: &e];
                
                if (!e){
                    
                    NSString* success = [json objectForKey:@"success"];
                    if ([success isEqualToString:@"True"]){
                        NSDictionary* userInfo = @{@"result": @"success"};
                        
                        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                        [nc postNotificationName:@"logged" object:self userInfo:userInfo];
                        [self deleteLocalLogs];
                        
                    }
                }else{
                    NSLog(@"error saving logs!");
                    NSDictionary* userInfo = @{@"result": @"error"};
                    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                    [nc postNotificationName:@"logged" object:self userInfo:userInfo];
                }
            
            }
            
            
            NSLog(@"%@", result);
        }
    }
}

-(NSString*) serverurl{
    NSString *country = [[NSUserDefaults standardUserDefaults] stringForKey:@"country"];
    
    if ([country isEqualToString:@"uk"]){
        return [[NSUserDefaults standardUserDefaults] stringForKey:@"uk_server_url"];
    }
    else{
       return[[NSUserDefaults standardUserDefaults] stringForKey:@"fr_server_url"];
    }
    
   
}
-(void) deleteLocalLogs{
    NSString *fileName = [NSString stringWithFormat:@"%@/samples.json", [self documentsDirectory]];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr fileExistsAtPath:fileName]){
        NSError* error;
    
        if ([fileMgr removeItemAtPath:fileName error:&error] != YES){
            NSLog(@"could not remove file!! %@", [error localizedDescription]);
        }
    }
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return (paths.count)? paths[0] : nil;
}

-(void) logToFile:(NSString*)content{
    content = [NSString stringWithFormat:@"%@\n",content];
    NSString *fileName = [NSString stringWithFormat:@"%@/samples.json", [self documentsDirectory]];
    
    
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:fileName];
    if (fh){
        [fh seekToEndOfFile];
        [fh writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
       
    }
    else{
        NSError *error = nil;
        [content writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:&error];
      
    }
}

@end
