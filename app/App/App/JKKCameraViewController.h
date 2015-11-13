//
//  JKKCameraViewController.h
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
#pragma once
#import <UIKit/UIKit.h>

#import "JKKModel.h"
#import "JKKResult.h"
#import "JKKCaptureManager.h"
#import "JKKCameraOverlayView.h"

#import "RegressionFactory.h"

@interface JKKCameraViewController : UIViewController <UIAlertViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property JKKModel* test;
@property JKKResult* result;
@property float calibrationValue;

@property CameraState state;
@property (getter=isTakingCalibrationPoint) BOOL takingCalibrationPoint;

@property (strong, nonatomic) IBOutlet UIImageView *cameraView;
@property (strong, nonatomic) IBOutlet JKKCameraOverlayView *cameraOverlayView;
@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;

@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;


@end
