//
//  JKKTestViewController.h
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

#pragma once
#import <UIKit/UIKit.h>
#import "JKKModel.h"
#import "RegressionFactory.h"

@interface JKKTestViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UINavigationItem *navBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@property (strong, nonatomic) IBOutlet UITextField *nameField;
@property (strong, nonatomic) IBOutlet UITextField *unitsField;
@property (strong, nonatomic) IBOutlet UILabel *roiLabel;
@property (strong, nonatomic) IBOutlet UIButton *setROIButton;

@property (strong, nonatomic) IBOutlet UILabel *componentsLabel;
@property (strong, nonatomic) IBOutlet UITableView *componentsTable;
@property (strong, nonatomic) IBOutlet UIButton *addComponentButton;
@property (strong, nonatomic) IBOutlet UIButton *removeComponentButton;

- (IBAction)unwindToTestView:(UIStoryboardSegue *)segue;

@property JKKModel* test;

@end
