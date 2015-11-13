//
//  JKKTestViewController.m
//  App
//
//  Created by Kevin on 1/26/14.
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

#import "JKKTestViewController.h"
#import "JKKCameraViewController.h"
#import "JKKAddComponentViewController.h"
#import "JKKROIViewController.h"

@interface JKKTestViewController ()

@property float calibrationValue;

@property NSMutableArray* componentItems;
@property int selectedComponentIndex;

@property float roiX;
@property float roiY;
@property float roiR;
@property BOOL roiSet;

@end

RegressionFactory factory;

@implementation JKKTestViewController

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
	// Do any additional setup after loading the view.
    
    [self.componentsTable setDataSource:self];
    [self.componentsTable setDelegate:self];
    
    [self.nameField setDelegate:self];
    [self.unitsField setDelegate:self];
    
    self.componentItems = [[NSMutableArray alloc] init];
    
    self.roiSet = NO;
    
    [self populateControls];
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

// hessk: called initially to match interface to current JKKModel and do other UI config
- (void)populateControls {
    
    // hessk: user can only add components if they've set the region of interest
    if (self.roiSet) {
        [self.roiLabel setText:[NSString stringWithFormat:@"X: %.0f  Y: %.0f  Radius: %.0f", self.roiX, self.roiY, self.roiR]];
        [self.setROIButton setTitle:@"Change" forState:UIControlStateNormal];
        [self.addComponentButton setEnabled:YES];
    } else {
        [self.setROIButton setTitle:@"Set" forState:UIControlStateNormal];
        [self.addComponentButton setEnabled:NO];
    }
    
    // hessk: user can only remove components/move onto the next step if there are components
    
    if (self.selectedComponentIndex >= 0 && [self.componentItems count] > 0) {
        [self.removeComponentButton setEnabled:YES];
    } else {
        [self.removeComponentButton setEnabled:NO];
    }
    
    if ([self.componentItems count] > 0) {
        [self.nextButton setEnabled:YES];
    } else {
        [self.nextButton setEnabled:NO];
    }
    
}

- (IBAction)removeComponent:(id)sender {
    [self.componentItems removeObjectAtIndex:self.selectedComponentIndex];
    [self.componentsTable reloadData];
    
    NSIndexPath *lastItemPath = [NSIndexPath indexPathForRow:[self.componentItems count] - 1 inSection:0];
    [self.componentsTable selectRowAtIndexPath:lastItemPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    [self populateControls];
}

- (IBAction)updateTitle:(id)sender {
    self.navBar.title = [(UITextField *)sender text];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // hessk: pass pointers on for calibration if a calibration is being run
    if ([[segue identifier] isEqualToString:@"showCalibrationList"] && !self.test) {
        // hessk: initialize a test if there isn't one
        NSLog(@"Creating a new model...");
        std::string* modelName;
        if (self.nameField.text.length > 0) {
            modelName = new std::string([self.nameField.text UTF8String]);
        } else {
            modelName = new std::string([@"No name" UTF8String]);
        }
        
        NSString *modelUnits;
        if (self.unitsField.text.length > 0) {
            modelUnits = self.unitsField.text;
        } else {
#warning TODO: user should not be able to continue without entering units
            modelUnits = @"units";
        }
        
        factory.createNew(*modelName, *modelName);
        
        JKKComponent* currentComponent;
        for (int i = 0; i < [self.componentItems count]; i++) {
            currentComponent = [self.componentItems objectAtIndex:i];
            factory.addNewComponent([currentComponent modelType], [currentComponent startTime], [currentComponent endTime], [currentComponent varType]);
        }
        
        self.test = [[JKKModel alloc] initWithModel:factory.getCreatedModel() units:modelUnits];
        self.test.model->setIndices(3, 2, 1, 0);
        
        self.test.model->setCircle(self.roiX, self.roiY, self.roiR);
    
        
        [[segue destinationViewController] setTest:self.test];
    } else if ([[segue identifier] isEqualToString:@"showROI"]) {
        if (self.roiSet) {
            [[segue destinationViewController] setX:self.roiX];
            [[segue destinationViewController] setY:self.roiY];
            [[segue destinationViewController] setR:self.roiR];
        } else {
#warning Just used arbitrary numbers here
            [[segue destinationViewController] setX:250];
            [[segue destinationViewController] setY:250];
            [[segue destinationViewController] setR:100];
        }
    }
    
    
}

- (IBAction)unwindToTestView:(UIStoryboardSegue *)segue {
    UIViewController* sourceController = segue.sourceViewController;
    
    if ([sourceController isKindOfClass:[JKKAddComponentViewController class]]) {
        // hessk: add new component to component items
        JKKAddComponentViewController* source = (JKKAddComponentViewController*)sourceController;
        JKKComponent* item = [source component];
        
        if (item != nil) {
            // hessk: add new component to components table and make sure it's selected
            NSIndexPath *itemPath = [NSIndexPath indexPathForRow:[self.componentItems count] inSection:0];
            [self.componentItems addObject:item];
            [self.componentsTable reloadData];
            [self.componentsTable selectRowAtIndexPath:itemPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
    } else if ([sourceController isKindOfClass:[JKKROIViewController class]]) {
        JKKROIViewController* source = (JKKROIViewController*)sourceController;
        
        self.roiX = source.x;
        self.roiY = source.y;
        self.roiR = source.r;
        
        self.roiSet = YES;
    }
    
    [self populateControls];
}

/* hessk: hides the keyboard if the user touches anywhere other than the specified views
 by "resigning" them as "first responders" */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.nameField isFirstResponder] && [touch view] != self.nameField) {
        [self.nameField resignFirstResponder];
    } else if ([self.unitsField isFirstResponder] && [touch view] != self.unitsField) {
        [self.unitsField resignFirstResponder];
    }
    
    [super touchesBegan:touches withEvent:event];
}

#pragma mark UITableViewDelegate/DataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (tableView == self.componentsTable) {
        return [self.componentItems count];
    } else {
        //error: either throw an error or give a default value
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    
    if (tableView == self.componentsTable) {
        cellIdentifier = @"ComponentsPrototypeCell";
    } else {
        //error
    }
    
    // hessk: assign specified prototype cell to this cell and get appropriate object from array at the same index
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (tableView == self.componentsTable) {
        JKKComponent* componentItem = [self.componentItems objectAtIndex:indexPath.row];
         
        // hessk: Get references to the prototype cells subviews by their tags (defined in IB)
        // But using literals like this is awkward. Consider alternatives.
        UILabel* title = (UILabel *)[cell.contentView viewWithTag:20];
        UILabel* detail = (UILabel *)[cell.contentView viewWithTag:21];
        
        [title setText:[NSString stringWithFormat:@"%@ (%@)", [componentItem getModelTypeString], [componentItem getVarTypeString]]];
        [detail setText: [NSString stringWithFormat:@"%.0fs to %.0fs", [componentItem startTime], [componentItem endTime]]];
    } else {
        //error
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // hessk: react to row selection here
    self.selectedComponentIndex = indexPath.row;
    [self populateControls];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedComponentIndex = -1;
    [self populateControls];
}

#pragma mark UITextFieldDelegate methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
