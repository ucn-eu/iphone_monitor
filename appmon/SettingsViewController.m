//
//  SettingsViewController.m
//  appmon
//
//  Created by Tom Lodge on 23/10/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end


@implementation SettingsViewController

@synthesize selectedIndex;

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
    [self.countryControl setSelectedSegmentIndex:selectedIndex];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)countryChanged:(UISegmentedControl*)sender {
   
    NSString * country = [sender titleForSegmentAtIndex:  sender.selectedSegmentIndex];
   
    [self.delegate didSelectCountry:country];
}

- (IBAction)doneClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
