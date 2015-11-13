//
//  JKKConfigViewController.m
//  App
//
//  Created by Kevin on 2/10/14.
/* ========================================================================
 *  Copyright 2014 Kyle Cesare, Kevin Hess, Joe Runde, Chadd Armstrong, Chris Heist
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * ========================================================================
 */

#import "JKKConfigViewController.h"

/* display pixel density for a circle based on the fps settings and x, y configuration */

@interface JKKConfigViewController ()

@end

@implementation JKKConfigViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // hessk: TODO: populate location segmented control labels with camera location enumeration
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.lightingSlider.maximumValue = 1.0f;
    self.lightingSlider.minimumValue = 0.0f;
    [self.lightingSlider setContinuous:YES];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSInteger fps = [defaults integerForKey:@"kFPS"];
    NSInteger lightingLevel = [defaults floatForKey:@"kLightingLevel"];
    NSInteger cameraLocation = [defaults integerForKey:@"kCameraLocation"];
    NSInteger cameraLighting = [defaults integerForKey:@"kCameraLighting"];    /*
    ROIMode roiMode = (ROIMode)[defaults integerForKey:@"kROIMode"];
    NSInteger roiX = [defaults integerForKey:@"kROIX"];
    NSInteger roiY = [defaults integerForKey:@"kROIY"];
    NSInteger roiR = [defaults integerForKey:@"kROIR"];
    
    [self.roiModeSegControl setSelectedSegmentIndex:roiMode];
    [self.roiXField setText:[NSString stringWithFormat:@"%ld", (long)roiX]];
    [self.roiYField setText:[NSString stringWithFormat:@"%ld", (long)roiY]];
    [self.roiRField setText:[NSString stringWithFormat:@"%ld", (long)roiR]];
    
    
    if (roiMode == AUTOMATIC) {
        [self.roiXField setEnabled:NO];
        [self.roiYField setEnabled:NO];
        [self.roiRField setEnabled:NO];
    } else if (roiMode == MANUAL) {
        [self.roiXField setEnabled:YES];
        [self.roiYField setEnabled:YES];
        [self.roiRField setEnabled:YES];
    } else {
        NSLog(@"Undefined ROI mode.");
    }
     */
    [self.lightingSegControl setSelectedSegmentIndex:cameraLighting];
    [self.locationSegControl setSelectedSegmentIndex:cameraLocation];
    [self.lightingSlider setValue:lightingLevel];\
    [self.lightingLevelLabel setText:[NSString stringWithFormat:@"%.1f", [self.lightingSlider value]]];
    [self.fpsStepper setValue:fps];
    [self updateGUI:self.fpsStepper];
    [self updateGUI:self.lightingSegControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (IBAction)updateGUI:(id)sender {
    if (sender == self.lightingSlider) {
        float tmp = [self.lightingSlider value];
        [self.lightingLevelLabel setText:[NSString stringWithFormat:@"%.1f", [self.lightingSlider value]]];
    }
    else if (sender == self.fpsStepper) {
        [self.fpsLabel setText:[NSString stringWithFormat:@"%.0f", [self.fpsStepper value]]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[self.lightingSegControl selectedSegmentIndex] forKey:@"kCameraLighting"];
    [defaults setInteger:[self.locationSegControl selectedSegmentIndex] forKey:@"kCameraLocation"];
    [defaults setInteger:[self.fpsStepper value] forKey:@"kFPS"];
    [defaults setFloat:[self.lightingSlider value] forKey:@"kLightingLevel"];
}

- (void)sliderDidChange:(UISlider *)slider
{
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 4;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"fpsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
 */

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
