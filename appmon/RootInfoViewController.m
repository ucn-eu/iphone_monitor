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
@synthesize loggingError;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    self.loggingError = 0;
    [self monitorSystem:nil];
     [[NSNotificationCenter defaultCenter] addObserverForName:@"logged" object:nil queue:nil usingBlock:^(NSNotification *note) {
         NSDictionary *result = [note userInfo];
         
         if ([[result objectForKey:@"result"] isEqualToString:@"success"]){
             self.loggingError = 1;
             _lastLoggedLabel.text = @"just now";
         }else{
             long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]longValue];
             self.loggingError = 0;
             _lastLoggedLabel.text =  @"ERROR just now";
         }
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(monitorSystem:) userInfo:nil repeats:YES];
    
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
    
    if (self.loggingError){
    _lastLoggedLabel.text =  [NSString stringWithFormat:@"ERROR %@ ago", [Util tsToString:(now - [[ProcessLogger logger] lastLog])]];
    }else{
        _lastLoggedLabel.text =  [NSString stringWithFormat:@"%@ ago", [Util tsToString:(now - [[ProcessLogger logger] lastLog])]];
    }
    
    processViewController.processes = [self filter:processes];
    [processViewController.tableView reloadData];
    //[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"processview_embed"]){
        NSDictionary *data = [[ProcessLogger logger] sample];
        NSArray *processes      = [data objectForKey:@"processes"];
        
        processViewController  = (ProcessViewController*) [segue destinationViewController];
        processViewController.processes = [self filter:processes];
    }
    else if ([segue.identifier isEqualToString:@"settings_segue"]){
        SettingsViewController* settingsViewController  = (SettingsViewController*) [segue destinationViewController];
        [settingsViewController setDelegate:self];
        [settingsViewController setSelectedIndex:[self countryIndex]];
       
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

-(int) countryIndex{
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    NSString *country = [prefs stringForKey:@"country"];
    
    [prefs setObject:country forKey:@"country"];
    if ([country isEqualToString:@"uk"]){
        return 0;
    }
    return 1;
    
}

-(NSArray *) filter:(NSArray *) processes
{
   
    NSArray *filterout = @[@"AdSheet"
      ,@"AppleIDAuthAgent"
      ,@"BTLEServer"
      ,@"BTServer"
      ,@"BlueTool"
      ,@"CFNetworkAgent"
      ,@"CloudKeychainPro"
      ,@"CommCenter"
      ,@"CommCenterMobile"
      ,@"DuetLST"
      ,@"EscrowSecurityAl"
      ,@"IMDPersistenceAg"
      ,@"IMLoggingAgent"
      ,@"IMRemoteURLConne"
      ,@"MobileCal"
      ,@"MobileGestaltHel"
      ,@"MobileMail"
      ,@"MobilePhone"
      ,@"MobileStorageMou"
      ,@"SCHelper"
      ,@"SpringBoard"
      ,@"StoreKitUIServic"
      ,@"UserEventAgent"
      ,@"absd"
      ,@"accountsd"
      ,@"adid"
      ,@"afcd"
      ,@"aggregated"
      ,@"amfid"
      ,@"aosnotifyd"
      ,@"apsd"
      ,@"assetsd"
      ,@"assistantd"
      ,@"atc"
      ,@"awdd"
      ,@"backboardd"
      ,@"backupd"
      ,@"calaccessd"
      ,@"com.apple.Mobile"
      ,@"com.apple.Stream"
      ,@"configd"
      ,@"coresymbolicatio"
      ,@"cplogd"
      ,@"daily"
      ,@"dataaccessd"
      ,@"debugserver"
      ,@"deleted"
      ,@"distnoted"
      ,@"fairplayd.H1"
      ,@"fseventsd"
      ,@"geod"
      ,@"hpfd"
      ,@"iaptransportd"
      ,@"identityservices"
      ,@"imagent"
      ,@"installd"
      ,@"itunescloudd"
      ,@"itunesstored"
      ,@"kbd"
      ,@"kernel_task"
      ,@"keybagd"
      ,@"launchctl"
      ,@"launchd"
      ,@"librariand"
      ,@"limitadtrackingd"
      ,@"locationd"
      ,@"lockbot"
      ,@"lockdownd"
      ,@"lsd"
      ,@"mDNSResponder"
      ,@"medialibraryd"
      ,@"mediaremoted"
      ,@"mediaserverd"
      ,@"misd"
      ,@"mobile_assertion"
      ,@"mobile_installat"
      ,@"mobile_storage_p"
      ,@"mobileassetd"
      ,@"mstreamd"
      ,@"networkd"
      ,@"networkd_privile"
      ,@"notification_pro"
      ,@"notifyd"
      ,@"passd"
      ,@"pasteboardd"
      ,@"powerd"
      ,@"prdaily"
      ,@"profiled"
      ,@"ptpd"
      ,@"recentsd"
      ,@"routined"
      ,@"sandboxd"
      ,@"securityd"
      ,@"softwarebehavior"
      ,@"softwareupdated"
      ,@"softwareupdatese"
      ,@"storebookkeeperd"
      ,@"syncdefaultsd"
      ,@"syslog_relay"
      ,@"syslogd"
      ,@"tccd"
      ,@"timed"
      ,@"touchsetupd"
      ,@"ubd"
      ,@"vmd"
      ,@"voiced"
      ,@"vsassetd"
      ,@"wifid"
      ,@"wirelessproxd"
      ,@"xpcd"];

    NSMutableArray *filtered = [NSMutableArray array];

    for (int i = 0; i < [processes count]; i++){
        NSDictionary *p = [processes objectAtIndex:i];
        if (![filterout containsObject:[p objectForKey:@"name"]]) {
            [filtered addObject:p];
        }
    }
    
    return filtered;
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

-(void) didSelectCountry:(NSString*) country{
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:country forKey:@"country"];
    [prefs synchronize];
    NSLog(@"set the country to %@", country);
    NSString *settingc = [[NSUserDefaults standardUserDefaults] stringForKey:@"country"];
    NSLog(@"re-read from settings, the country to %@", settingc);
    
    
}

@end
