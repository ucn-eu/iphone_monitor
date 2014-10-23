//
//  SettingsViewController.h
//  appmon
//
//  Created by Tom Lodge on 23/10/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsDelegate.h"

@interface SettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *countryControl;
@property (assign, nonatomic) int selectedIndex;
@property(assign, nonatomic) id <SettingsDelegate> delegate;
- (IBAction)countryChanged:(id)sender;
- (IBAction)doneClicked:(id)sender;


@end
