//
//  JKKCaptureManager.h
//  CameraControl
//
//  Created by Kevin on 11/15/13.
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
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface JKKCaptureManager : NSObject 

@property AVCaptureSession *session;
@property AVCaptureDevice *device;

- (void)initializeSession;
- (void)initializeDevice: (BOOL) useFront;
- (void)initializeVideoOutWithFPS: (int)fps usingDelegate: (id)delegate;
- (void)initializePreviewLayerUsingView: (UIImageView*)cameraView withLayer: (AVCaptureVideoPreviewLayer*)layer;

- (void)startSession;
- (void)stopSession;

- (void)toggleAutoExposure;
- (void)toggleAutoWB;
- (void)toggleAutoFocus;
- (void)toggleTorch;
- (void)turnTorchOn: (float) level;

@end
