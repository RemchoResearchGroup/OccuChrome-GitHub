//
//  JKKCalibrationListViewController.m
//  App
//
//  Created by Kevin on 3/12/14.
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

#import "JKKCalibrationListViewController.h"
#import "JKKGraphViewController.h"
#import "JKKCameraViewController.h"

@interface JKKCalibrationListViewController ()

@property float newCalibrationValue;
@property NSMutableArray *calibrationItems;

@property UIAlertView *calibrationAlert;
@property UIAlertView *graphModelAlert;
@property UIAlertView *selectTypeAlert;

@property RegressionModel::RegressionType graphRegressionType;

@end

@implementation JKKCalibrationListViewController

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
    
    [self.calibrationTable setDelegate:self];
    [self.calibrationTable setDataSource:self];
    self.calibrationItems = [[NSMutableArray alloc] init];
    
    self.calibrationAlert = [[UIAlertView alloc] initWithTitle:@"Calibration value" message:[NSString stringWithFormat:@"Please enter the value of this sample in %@", self.test.units] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
    self.calibrationAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // hessk: TODO: use enumeration for button titles
    self.graphModelAlert = [[UIAlertView alloc] initWithTitle:@"Graph model" message:@"Please select a regression mode." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Planar", @"PCA Linear", @"PCA Quadratic", @"PCA Exponential", nil];
    self.graphModelAlert.alertViewStyle = UIAlertViewStyleDefault;
    
    self.selectTypeAlert = [[UIAlertView alloc] initWithTitle:@"Select regression type" message:@"Please select a regression mode." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Planar", @"PCA Linear", @"PCA Quadratic", @"PCA Exponential", nil];
    self.selectTypeAlert.alertViewStyle = UIAlertViewStyleDefault;
    
    [self updateControls];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showCameraForCalibration"]) {
        [[segue destinationViewController] setTest:self.test];
        [[segue destinationViewController] setCalibrationValue:self.newCalibrationValue];
        [[segue destinationViewController] setTakingCalibrationPoint:YES];
    } else if ([[segue identifier] isEqualToString:@"returnToTestFromCalibration"]) {
        //hessk: TODO: add warning that model data is going to be dropped
        [[segue destinationViewController] setTest:nil];
    } else if ([[segue identifier] isEqualToString:@"showGraphFromList"]) {
        [[segue destinationViewController] setTest:self.test];
        [[segue destinationViewController] setPca:NO];
    } else if ([[segue identifier] isEqualToString:@"showModelGraphFromList"]) {
        [[segue destinationViewController] setTest:self.test];
        [[segue destinationViewController] setRegressionType:self.graphRegressionType];
        [[segue destinationViewController] setPca:YES];
        [[segue destinationViewController] setNumCalibrationValues:[self.calibrationItems count]];
    }
}

- (IBAction)unwindToCalibrationList:(UIStoryboardSegue*)segue {
    [self updateControls];
}

- (void)updateControls {
    //update table
    [self.calibrationItems removeAllObjects];
    for (int i = 0; i < self.test.model->getNumCalibrations(); i++) {
        [self.calibrationItems addObject:[NSNumber numberWithFloat:self.test.model->getCalibrationConcentration(i)]];
    }
    [self.calibrationTable reloadData];
    
    //enable finish button depending on whether they've done enough calibrations
    [self.finishButton setEnabled:self.test.model->isCalibrated()];
    [self.graphModelButton setEnabled:self.test.model->isCalibrated()];
    [self.setTypeButton setEnabled:self.test.model->isCalibrated()];
    
    [self.showGraphButton setEnabled:(self.calibrationItems.count > 0)];
    
    RegressionModel::RegressionType type = self.test.model->getCurrentRegressionType();
    NSString *regressionString;
    
    switch (type) {
        case RegressionModel::PLANAR:
            regressionString = @"Planar";
            break;
        case RegressionModel::PCA_LINEAR:
            regressionString = @"PCA Linear";
            break;
        case RegressionModel::PCA_QUADRATIC:
            regressionString = @"PCA Quadratic";
            break;
        case RegressionModel::PCA_EXPONENTIAL:
            regressionString = @"PCA Exponential";
            break;
        case RegressionModel::INVALID_TYPE:
        default:
            regressionString = @"Invalid type";
            break;
    }
    
    [self.typeLabel setText:regressionString];
}

- (IBAction)addCalibrationPoint:(id)sender {
    [[self.calibrationAlert textFieldAtIndex:0] resignFirstResponder];
    [[self.calibrationAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
    [[self.calibrationAlert textFieldAtIndex:0] becomeFirstResponder];
    
    [[self.calibrationAlert textFieldAtIndex:0] setText:@""];
    
    [self.calibrationAlert show];
}

- (IBAction)graphModel:(id)sender {
    [self.graphModelAlert show];
}

- (IBAction)setModelType:(id)sender {
    [self.selectTypeAlert show];
}

#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.calibrationAlert) { //executed after values entered in the popup window and "continue" pressed  -- strarm
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSLog(@"Calibration val entered: %@", [[alertView textFieldAtIndex:0] text]);
            [self setNewCalibrationValue:[[[alertView textFieldAtIndex:0] text] floatValue]];
            // Dont want to go to the camera just yet -- save for after the full calibration set is defined.
            [self performSegueWithIdentifier:@"showCameraForCalibration" sender:self];
        }
    } else if (alertView == self.graphModelAlert) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Planar"]) {
                self.graphRegressionType = RegressionModel::PLANAR;
            } else if ([title isEqualToString:@"PCA Linear"]) {
                self.graphRegressionType = RegressionModel::PCA_LINEAR;
            } else if ([title isEqualToString:@"PCA Quadratic"]) {
                self.graphRegressionType = RegressionModel::PCA_QUADRATIC;
            } else if ([title isEqualToString:@"PCA Exponential"]) {
                self.graphRegressionType = RegressionModel::PCA_EXPONENTIAL;
            } else {
                self.graphRegressionType = RegressionModel::INVALID_TYPE;
            }
            
            [self performSegueWithIdentifier:@"showModelGraphFromList" sender:self];
        }
    } else if (alertView == self.selectTypeAlert) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Planar"]) {
                self.test.model->setRegressionType(RegressionModel::PLANAR);
            } else if ([title isEqualToString:@"PCA Linear"]) {
                self.test.model->setRegressionType(RegressionModel::PCA_LINEAR);
            } else if ([title isEqualToString:@"PCA Quadratic"]) {
                self.test.model->setRegressionType(RegressionModel::PCA_QUADRATIC);
            } else if ([title isEqualToString:@"PCA Exponential"]) {
                self.test.model->setRegressionType(RegressionModel::PCA_EXPONENTIAL);
            } else {
                self.test.model->setRegressionType(RegressionModel::INVALID_TYPE);
            }
            
            [self updateControls];
        }
    }
    
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
    return self.test.model->getNumCalibrations();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    
    if (tableView == self.calibrationTable) {
        cellIdentifier = @"CalibrationPrototypeCell";
    } else {
        //error
    }
    
    // hessk: assign specified prototype cell to this cell and get appropriate object from array at the same index
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (tableView == self.calibrationTable) {
        NSNumber* calibrationPointValue = [self.calibrationItems objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%.2f %@", [calibrationPointValue floatValue], self.test.units];
    } else {
        //error
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // hessk: react to row selection here
    self.test.model->setStatsForCalibration(indexPath.row);
    [self.calibrationStatsTextView setText:[NSString stringWithCString:self.test.model->getStatData().c_str() encoding:NSUTF8StringEncoding]];
}


@end
