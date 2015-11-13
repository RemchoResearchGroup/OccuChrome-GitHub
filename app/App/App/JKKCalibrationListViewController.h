//
//  JKKCalibrationListViewController.h
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

#import <UIKit/UIKit.h>
#import "JKKModel.h"
#import "JKKTestViewController.h"

@interface JKKCalibrationListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (IBAction)unwindToCalibrationList:(UIStoryboardSegue *)segue;
@property (strong, nonatomic) IBOutlet UITableView *calibrationTable;

@property (strong, nonatomic) IBOutlet UITextView *calibrationStatsTextView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *finishButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showGraphButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *graphModelButton;
@property (strong, nonatomic) IBOutlet UIButton *setTypeButton;
@property (strong, nonatomic) IBOutlet UILabel *typeLabel;

@property JKKModel* test;

@end
