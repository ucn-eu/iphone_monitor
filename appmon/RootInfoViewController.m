//
//  RootInfoViewController.m
//  appmon
//
//  Created by Tom Lodge on 07/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "RootInfoViewController.h"

@interface RootInfoViewController ()

@end

@implementation RootInfoViewController

@synthesize processViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self monitorSystem:nil];
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(monitorSystem:) userInfo:nil repeats:YES];
    
	// Do any additional setup after loading the view.
}


/*
-(void) testdates{
    NSString *now = @"12:59";
    
    NSArray *fromarray = @[@"12:58", @"07:34", @"12:00", @"14:40", @"14:50", @"14.46", @"23:30", @"23:30"];
    NSArray *toarray = @[@"00:01",@"08:45", @"14:30", @"15:30", @"14:30", @"14.47", @"06:00", @"14:46"];
    
    
    for (int i = 0; i < [fromarray count]; i++){
    
        NSString *from = fromarray[i];
        NSString *to = toarray[i];
        
        BOOL inside = [Util amInsideTimeRange:from to:to now:now];
    
        NSLog(@"%@ between %@ and %@ is %@", now, from, to, inside ? @"YES": @"NO");
    }
}*/

- (void)monitorSystem:(NSTimer *)timer {
    
    if ([Util amInsideTimeRange:[[ProcessLogger logger] from] to:[[ProcessLogger logger] to]]){
        self.pausedLabel.alpha = 1.0;
    }else{
         self.pausedLabel.alpha = 0.0;
    }
         
    NSDictionary *data;
    
    data = [[ProcessLogger logger] sample];
    
    NSDictionary *network   = [data objectForKey:@"network"];
    
    NSArray *processes      = [data objectForKey:@"processes"];
    
    NSString *uptime        = [data objectForKey:@"uptime"];
    //NSString *battery       = [data objectForKey:@"battery"];
    
    _uptimeLabel.text = uptime;
    _wifiUpLabel.text = [NSString stringWithFormat:@"%@", [network objectForKey:@"wifiup"]];
    _wifiDownLabel.text = [NSString stringWithFormat:@"%@", [network objectForKey:@"wifidown"]];
    _cellUpLabel.text =[NSString stringWithFormat:@"%@", [network objectForKey:@"cellup"]];
    _cellDownLabel.text =[NSString stringWithFormat:@"%@", [network objectForKey:@"celldown"]];

    long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
    
    _lastLoggedLabel.text =  [NSString stringWithFormat:@"%@ ago", [Util tsToString:(now - [[ProcessLogger logger] lastLog])]];
    
    processViewController.processes = processes;
    [processViewController.tableView reloadData];
    //[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSDictionary *data = [[ProcessLogger logger] sample];
    NSArray *processes      = [data objectForKey:@"processes"];
    
    if ([segue.identifier isEqualToString:@"processview_embed"]){
        processViewController  = (ProcessViewController*) [segue destinationViewController];
        processViewController.processes = processes;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logToServer:(id)sender {
    NSLog(@"Logging to server!!");
    [[ProcessLogger logger] logToServer];
}

@end
