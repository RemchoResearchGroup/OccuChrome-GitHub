//
//  JKKCaptureManager.m
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

#import "JKKCaptureManager.h"

@implementation JKKCaptureManager

- (void)initializeSession {
    self.session = [[AVCaptureSession alloc] init];
    /*      @strarm June 20, 2014
     * Consider cost trade off of low rez/high framerate vs high rez/low framerate
     * Processing overhead is a consideration -- benchmarking needed to declare ideal combo
     */
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    } else {
        throw [NSException exceptionWithName:@"SessionInitializationException" reason:@"640x480 session preset not available" userInfo:nil];
    }
}

- (void)initializeDevice:(BOOL) useFront {
    NSError *error;
    
    //hessk: define the device for the sessions: using default device here
    NSLog(@"Capture manager: setting device for session...");
    
    AVCaptureDevice* newDevice;
    
    if (useFront) {
        newDevice = [self getFrontCamera];
    } else {
        newDevice = [self getBackCamera];
    }
    
    if (!newDevice) {
        throw [NSException exceptionWithName:@"CameraInitializationException" reason:nil userInfo:nil];
    }
    
    NSLog(@"Capture manager: changing camera settings...");
    //hessk: change various camera settings
    //white balance
    if ([newDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        if ([newDevice lockForConfiguration:&error]) {
            newDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            [newDevice unlockForConfiguration];
        } else {
            //TODO: handle error
            NSLog(@"Capture manager: lock error occurred while trying to set white balance.");
        }
    }
    
    //exposure
    if ([newDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        if ([newDevice lockForConfiguration:&error]) {
            newDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            [newDevice unlockForConfiguration];
        } else {
            //TODO: handle error
            NSLog(@"Capture manager: lock error occurred while trying to set exposure mode");
        }
    }
    
    //focus
    if ([newDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        if ([newDevice lockForConfiguration:&error]) {
            newDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [newDevice unlockForConfiguration];
        } else {
            //TODO: handle error
            NSLog(@"Capture manager: lock error occurred while trying to set focus mode");
        }
    }
    
    
    self.device = newDevice;
    
    NSLog(@"Capture manager: initializing session video input...");
    //hessk: initialize inputs for sessions
    AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&error];
    [self.session addInput:videoIn];
}

- (void)initializeVideoOutWithFPS:(int)fps usingDelegate:(id)delegate{
    NSLog(@"Capture manager: initializing session video output...");
    //hessk: apple code stuffs
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [self.session addOutput:videoOut];
    
    /*      @strarm -- June 20, 2014
     *  From various references online, 32BGRA is a reasonable pixel format to choose, YUV may be "faster"
     *  unless of course you just convert it again once you get it, might as well ask for the dest format now.
     *  Also, to futureproof -- might consider the following:
     *      videoOutput.videoSettings = nil;
     *      
     *  and then the following to determine the format picked:
     *      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(source);
     *      CGColorSpaceRef cref = CVImageBufferGetColorSpace(imageBuffer);
     */
    videoOut.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    [self setFrameRate:fps];
    
    dispatch_queue_t queue = dispatch_queue_create("VideoOutQueue", NULL);
    [videoOut setSampleBufferDelegate:delegate queue:queue];
}

- (void)initializePreviewLayerUsingView:(UIImageView *)cameraView withLayer:(AVCaptureVideoPreviewLayer *)layer {
    NSLog(@"Capture manager: initializing camera preview layer...");
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    UIView *view = cameraView;
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    CGRect bounds = [view bounds];
    
    [newCaptureVideoPreviewLayer setFrame:bounds];
    [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [viewLayer addSublayer:newCaptureVideoPreviewLayer];
    
    layer = newCaptureVideoPreviewLayer;
}

- (void)startSession {
    NSLog(@"Capture manager: starting camera...");
    [self.session startRunning]; //AVCaptureSession begin capture
}

- (void)stopSession {
    NSLog(@"Capture manager: stopping camera");
    [self.session stopRunning]; //AVCaptureSession end capture
}

- (NSError*)setFrameRate: (int)fps {
    NSError *error;
    
    /* 
     * hessk: CMTimeMake creates a time interval with the first parameter as the numerator and the second
     * parameter as the denominator. So: 1, 25 -> minumum frame duration is 1/25 of a second.
     */
    
    [self.device lockForConfiguration:&error];
    self.device.activeVideoMinFrameDuration = CMTimeMake(1, fps);
    self.device.activeVideoMaxFrameDuration = CMTimeMake(1, fps);
    [self.device unlockForConfiguration];
    
    return error;
}

- (void)toggleAutoExposure {
    NSError *error;
    
    if ((self.device.exposureMode != AVCaptureExposureModeContinuousAutoExposure) && [self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [self.device lockForConfiguration:&error];
        self.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [self.device unlockForConfiguration];
    } else if ([self.device isExposureModeSupported:AVCaptureExposureModeLocked]) {
        [self.device lockForConfiguration:&error];
        self.device.exposureMode = AVCaptureExposureModeLocked;
        [self.device unlockForConfiguration];
    } else {
        NSLog(@"Error toggling exposure mode; exposure mode not supported for this camera.");
    }
    
}

- (void)toggleAutoWB {
    NSError *error;
    
    if (self.device.whiteBalanceMode != AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance && [self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        [self.device lockForConfiguration:&error];
        self.device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        [self.device unlockForConfiguration];
    } else if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        [self.device lockForConfiguration:&error];
        self.device.whiteBalanceMode = AVCaptureWhiteBalanceModeLocked;
        [self.device unlockForConfiguration];
    } else {
        NSLog(@"Error toggling white balance mode; white balance mode not supported for this camera.");
    }
    
    
}

- (void)toggleAutoFocus {
    NSError *error;
    
    if (self.device.focusMode != AVCaptureFocusModeContinuousAutoFocus && [self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [self.device lockForConfiguration:&error];
        self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [self.device unlockForConfiguration];
    } else if ([self.device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        [self.device lockForConfiguration:&error];
        self.device.focusMode = AVCaptureFocusModeLocked;
        [self.device unlockForConfiguration];
    } else {
        NSLog(@"Error toggling white balance mode; white balance mode not supported for this camera.");
    }
}

- (void) turnTorchOn: (float) level {
    NSError *error;
    if ([self.device hasTorch] && [self.device hasFlash]){
        if ([self.device lockForConfiguration:&error]) {
            if (level) {
                NSError* outError;
                [self.device setTorchModeOnWithLevel:level error:&outError];
                NSLog(@"Capture manager: setting lighting %f", level);
                //[self.device setTorchMode:AVCaptureTorchModeOn];
                //[self.device setFlashMode:AVCaptureFlashModeOn];
                //torchIsOn = YES;
            } else {
                [self.device setTorchMode:AVCaptureTorchModeOff];
                //[self.device setFlashMode:AVCaptureFlashModeOff];
                //torchIsOn = NO;
            }
            [self.device unlockForConfiguration];
        }else {
            NSLog(@"Capture manager: lock error occurred while trying to set torch mode");
        }
    }
}

- (void)toggleTorch {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //LED / Flash
    if ([defaults integerForKey:@"kCameraLighting"]){
        [self turnTorchOn:[defaults floatForKey:@"kLightingLevel"]];
    }else {
        [self turnTorchOn:false];
    }
}


- (AVCaptureDevice *)getFrontCamera {
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)getBackCamera {
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil;
}

@end



/*
hessk:
 This function returns an array of available devices on the system - may be useful.

 [AVCaptureDevice devices]
*/