//
//  JKKSetupViewController.m
//  App
//
//  Created by Kevin on 1/27/14.
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

#import "JKKSetupViewController.h"
#import "JKKHomeViewController.h"

#import "JKKDatabaseManager.h"

@interface JKKSetupViewController ()

@property MFMailComposeViewController *mailViewController;
@property NSString *calibrationData;
@property NSString *calibrationText;

@end

@implementation JKKSetupViewController

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
    
    if (self.test) {
        [self.navBar setTitle:[[self.test getModelName] stringByAppendingString:@" Setup"]];
    }
    
#ifndef dev
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.editButton setEnabled:NO];
    });
#endif
    
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

/* hessk: hides the keyboard if the user touches anywhere other than the specified views
 by "resigning" them as "first responders" */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.notesField isFirstResponder] && [touch view] != self.notesField) {
        [self.notesField resignFirstResponder];
    } else if ([self.subjectField isFirstResponder] && [touch view] != self.subjectField) {
        [self.subjectField resignFirstResponder];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // hessk: pass pointers on
    if ([[segue identifier] isEqualToString:@"showCameraFromSetup"]) {
        // initialize result data with information user enters here; subject, notes, etc
        JKKResult* newResult = [[JKKResult alloc] initNewResultWithName:[self.test getModelName]
                                                                subject:[self.subjectField text]
                                                                  notes:[self.notesField text]];
        
        self.result = newResult;
        
        [[segue destinationViewController] setTest:self.test];
        [[segue destinationViewController] setResult:self.result];
        [[segue destinationViewController] setTakingCalibrationPoint:NO];
    } else if ([[segue identifier] isEqualToString:@"deleteModelSegue"]) {
        DataStore p = [[JKKDatabaseManager sharedInstance] openDatabase];
        p.deleteModelEntry(self.test.model->getModelName());
        p.close();
    } else if ([[segue identifier] isEqualToString:@"showListFromSetup"]) {
        [[segue destinationViewController] setTest:self.test];
    }
}

- (IBAction)unwindToSetup:(id)sender {
    // Unwind to run the test again from the results screen
}

- (IBAction)deleteTestWithConfirmation:(id)sender {
    UIAlertView* deleteConfirmationAlert = [[UIAlertView alloc] initWithTitle:@"Delete model?" message:@"Are you sure you want to delete this model?"  delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    deleteConfirmationAlert.alertViewStyle = UIAlertViewStyleDefault;
    [deleteConfirmationAlert show];
}

- (IBAction)sendMail:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        
        self.mailViewController = [[MFMailComposeViewController alloc] init];
        self.mailViewController.mailComposeDelegate = self;
        
        DataExporter exporter = DataExporter(self.test.model);
        exporter.exportCalibration();
        
        self.calibrationData = [NSString stringWithUTF8String:exporter.getCSVData().c_str()];
        self.calibrationText = [NSString stringWithUTF8String:exporter.getTextData().c_str()];
        
        NSString *messageBody = [NSString stringWithFormat:@"Model: %@\n\n%@", self.test.getModelName, self.calibrationText];
        
        [self.mailViewController setSubject:@"Calibration Data"];
        [self.mailViewController setMessageBody:messageBody isHTML:NO];
        [self.mailViewController addAttachmentData:[self.calibrationData dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/csv" fileName:@"calibration.csv"];
    } else {
        NSLog(@"Unable to send mail on this device");
    }
    
    if (self.mailViewController) {
        [self presentViewController:self.mailViewController animated:YES completion:nil];
    }
}

#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [self performSegueWithIdentifier:@"deleteModelSegue" sender:self];
    }
}

#pragma mark MFMailComposeViewControllerDelegate methods
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if (result == MFMailComposeResultSent) {
        NSLog(@"Message sent");
    } else if (result == MFMailComposeResultFailed) {
        NSLog(@"Failed to send message");
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
