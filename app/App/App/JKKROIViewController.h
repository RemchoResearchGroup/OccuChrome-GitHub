//
//  JKKROIViewController.h
//  App
//
//  Created by Kevin on 4/23/14.
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

#import "JKKCaptureManager.h"
#import "JKKModel.h"
#import "JKKCameraOverlayView.h"

@interface JKKROIViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet JKKCameraOverlayView *cameraOverlayView;
@property (retain, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) IBOutlet UIImageView *cameraView;

@property (strong, nonatomic) JKKCaptureManager *captureManager;

-(IBAction)updateCirclePosition:(UIPanGestureRecognizer *)gesture;
-(IBAction)updateCircleRadius:(UIPinchGestureRecognizer *)sender;


@property float x;
@property float y;
@property float r;
@property float scaleX;
@property float scaleY;
@property CGPoint panCoord;

@property (strong, nonatomic) IBOutlet UILabel *xLabel;
@property (strong, nonatomic) IBOutlet UILabel *yLabel;
@property (strong, nonatomic) IBOutlet UILabel *rLabel;

@property (strong, nonatomic) IBOutlet UISwitch *autoSwitch;

@end
