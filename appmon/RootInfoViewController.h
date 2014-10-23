//
//  RootInfoViewController.h
//  appmon
//
//  Created by Tom Lodge on 07/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProcessLogger.h"
#import "ProcessViewController.h"
#import "SettingsViewController.h"
#import "Util.h"
#import "SettingsDelegate.h"
@interface RootInfoViewController : UIViewController<SettingsDelegate>
- (IBAction)logToServer:(id)sender;

@property (weak, nonatomic) ProcessViewController *processViewController;
@property (weak, nonatomic) IBOutlet UILabel *lastLoggedLabel;
@property (weak, nonatomic) IBOutlet UILabel *uptimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiUpLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellUpLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *pausedLabel;
@property (assign,nonatomic) int loggingError;
@end
