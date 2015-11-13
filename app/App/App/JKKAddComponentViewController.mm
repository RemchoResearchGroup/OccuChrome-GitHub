//
//  JKKAddComponentViewController.m
//  App
//
//  Created by Kevin on 2/8/14.
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

#import "JKKAddComponentViewController.h"

@interface JKKAddComponentViewController ()

@property NSInteger currentEndTimeMinutes;
@property NSInteger currentEndTimeSeconds;

@property NSInteger currentStartTimeMinutes;
@property NSInteger currentStartTimeSeconds;

@end

@implementation JKKAddComponentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.currentEndTimeMinutes = 0;
        self.currentEndTimeSeconds = 0;
        
        self.currentStartTimeMinutes = 0;
        self.currentStartTimeSeconds = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self initializeControls];
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

- (void)initializeControls {
    // hessk: TODO: temporarily removing colors until we can figure out how to handle the discrepancy between
    // segment index and subview index (can't just call "setTitle" on one of the subviews)
    
    //NSArray *colorSelectorSubviews = [self.channelSelector subviews];
    //[[colorSelectorSubviews objectAtIndex: ModelComponent::RED] setTintColor:[UIColor redColor]];
    [[self channelSelector] setTitle:@"Red" forSegmentAtIndex:ModelComponent::RED];
    
    //[[colorSelectorSubviews objectAtIndex: ModelComponent::GREEN] setTintColor:[UIColor blueColor]];
    [[self channelSelector] setTitle:@"Green" forSegmentAtIndex:ModelComponent::GREEN];
    
    //[[colorSelectorSubviews objectAtIndex: ModelComponent::BLUE] setTintColor:[UIColor greenColor]];
    [[self channelSelector] setTitle:@"Blue" forSegmentAtIndex:ModelComponent::BLUE];
    
    [[self typeSelector] setTitle:@"Point" forSegmentAtIndex:ModelComponent::POINT];
    [[self typeSelector] setTitle:@"Linear" forSegmentAtIndex:ModelComponent::LINEAR];
    [[self typeSelector] setTitle:@"Exponential" forSegmentAtIndex:ModelComponent::EXPONENTIAL];
}

- (IBAction)updateRuntime:(id)sender {
    /* hessk: TODO: clean this up. mixing UI elements and processing here */
    
    // handle end stepper wrap
    if (self.currentEndTimeSeconds == [self.secondStepper maximumValue] && [self.secondStepper value] == [self.secondStepper minimumValue]) {
        // positive wrap must've occurred...
        self.minuteStepper.value++;
    }
    if (self.currentEndTimeSeconds == [self.secondStepper minimumValue] && [self.secondStepper value] == [self.secondStepper maximumValue]) {
        // negative wrap must've occurred...
        self.minuteStepper.value--;
    }
    
    // handle start stepper wrap
    if (self.currentStartTimeSeconds == [self.startSecondStepper maximumValue] && [self.startSecondStepper value] == [self.startSecondStepper minimumValue]) {
        // positive wrap must've occurred...
        self.startMinuteStepper.value++;
    }
    if (self.currentStartTimeSeconds == [self.startSecondStepper minimumValue] && [self.startSecondStepper value] == [self.startSecondStepper maximumValue]) {
        // negative wrap must've occurred...
        self.startMinuteStepper.value--;
    }
    
    // ensure start time is less than end time
    if ([self getStartIntervalFromStepper] > [self getEndIntervalFromStepper]) {
        if (sender == self.startSecondStepper || sender == self.startMinuteStepper) {
            [self.minuteStepper setValue:[self.startMinuteStepper value]];
            [self.secondStepper setValue:[self.startSecondStepper value]];
        } else {
            [self.startMinuteStepper setValue:[self.minuteStepper value]];
            [self.startSecondStepper setValue:[self.secondStepper value]];
        }
    }
    
    self.currentEndTimeMinutes = [self.minuteStepper value];
    self.currentEndTimeSeconds = [self.secondStepper value];
    
    self.currentStartTimeMinutes = [self.startMinuteStepper value];
    self.currentStartTimeSeconds = [self.startSecondStepper value];
    
    [self updateRuntimeControls];
}

- (void)updateRuntimeControls {
    self.minuteLabel.text = [NSString stringWithFormat:@"%d min", self.currentEndTimeMinutes];
    self.secondLabel.text = [NSString stringWithFormat:@"%d sec", self.currentEndTimeSeconds];
    self.startMinuteLabel.text = [NSString stringWithFormat:@"%d min", self.currentStartTimeMinutes];
    self.startSecondLabel.text = [NSString stringWithFormat:@"%d sec", self.currentStartTimeSeconds];
    
    // second stepper wrapping dictated by max and min values of minute stepper
    if ((self.currentEndTimeMinutes > [self.minuteStepper minimumValue] || self.currentEndTimeSeconds > [self.secondStepper minimumValue]) && (self.currentEndTimeMinutes < [self.minuteStepper maximumValue] || self.currentEndTimeSeconds < [self.secondStepper maximumValue])) {
        [self.secondStepper setWraps:YES];
    } else {
        [self.secondStepper setWraps:NO];
    }
    
    // same for start time
    if ((self.currentStartTimeMinutes > [self.startMinuteStepper minimumValue] || self.currentStartTimeSeconds > [self.startSecondStepper minimumValue]) && (self.currentStartTimeMinutes < [self.startMinuteStepper maximumValue] || self.currentStartTimeSeconds < [self.startSecondStepper maximumValue])) {
        [self.startSecondStepper setWraps:YES];
    } else {
        [self.startSecondStepper setWraps:NO];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    /* check to see if the user pressed done - if so, set this controllers model component object */
    if (sender != self.doneButton) return;
    
    NSTimeInterval endTime = [self getEndIntervalFromStepper];
    NSTimeInterval startTime = [self getStartIntervalFromStepper];
    
    self.component = [[JKKComponent alloc] initWithVarType:(ModelComponent::VariableType)[self.channelSelector selectedSegmentIndex]
                                                         withModelType:(ModelComponent::ModelType)[self.typeSelector selectedSegmentIndex]
                                                         withStartTime:startTime
                                                         withEndTime:endTime];
    
}

- (NSTimeInterval)getStartIntervalFromStepper {
    return self.startMinuteStepper.value * 60 + self.startSecondStepper.value;
}

- (NSTimeInterval)getEndIntervalFromStepper {
    return self.minuteStepper.value * 60 + self.secondStepper.value;
}

@end
