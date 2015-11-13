//
//  JKKCameraViewController.m
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

#import "JKKCameraViewController.h"

#import "JKKResultsViewController.h"

#import "BiomarkerImageProcessor.h"
#import "DataExporter.h"
#import "DataStore.h"
#import "ResultEntry.h"
#import "JKKDatabaseManager.h"

@interface JKKCameraViewController ()


//@property RegressionFactory factory;
//@property RegressionModel* model;

@property float timeElapsed;
@property (strong, nonatomic) JKKCaptureManager* captureManager;

@property NSTimer* timer;
@property int timerCount;
@property AVAudioPlayer* alertSound;
@property NSDate* timerStartDate;

@end

NSUserDefaults* defaults;
BiomarkerImageProcessor processor;
bool overlayScaled = NO;
UIImage* outputImage;

const float TIMER_STEP = 0.1;

@implementation JKKCameraViewController

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
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    
    
    if (!self.test) NSLog(@"No test loaded.");

    [self setState: POSITIONING];
    
    // hessk: Timer setup
    self.timeElapsed = 0.0;
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:TIMER_STEP target:self selector:@selector(updateProgress:) userInfo:NULL repeats:YES];
    self.timerCount = 0;
    
    @try {
        // hessk: AVFoundation camera setup
        self.captureManager = [JKKCaptureManager new];
        [self.captureManager initializeSession];
        
        // hessk: camera location setup
        CameraLocation location = (CameraLocation)[defaults integerForKey:@"kCameraLocation"];
        switch (location) {
            case FRONT:
                [self.captureManager initializeDevice:YES];
                break;
            case BACK:
            default:
                [self.captureManager initializeDevice:NO];
                break;
        }
        
        [self.captureManager initializeVideoOutWithFPS:[defaults integerForKey:@"kFPS"] usingDelegate:self];
        [self.captureManager initializePreviewLayerUsingView:self.cameraView withLayer:self.captureVideoPreviewLayer];
        [self.captureManager startSession]; //AVCaptureSession begin capture
    } @catch (NSException *exception) {
        UIAlertView* calibrationValueAlert = [[UIAlertView alloc] initWithTitle:[exception name] message:[exception reason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        calibrationValueAlert.alertViewStyle = UIAlertViewStyleDefault;
        
        [calibrationValueAlert show];
    }
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

- (IBAction)startProcessing:(id)sender {
    if (self.timer != nil) {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
    }
    //[self.captureManager turnTorchOn:true];
    [self.captureManager toggleTorch];
    [self.captureManager toggleAutoExposure];
    [self.captureManager toggleAutoFocus];
    [self.captureManager toggleAutoWB];
    

    [self.startButton setEnabled:NO];
    [self.startButton setHidden:YES];
    [self setState:RUNNING];
    
    processor.reset();
    
    [self.statusLabel setText:@"Analyzing"];
    NSLog(@"Camera state set to RUNNING");
    
    // adds delay before calling endProcessing and sets the start date for the countdown label
    [self setTimerStartDate:[NSDate date]];
    [self performSelector:@selector(endProcessing) withObject:nil afterDelay: (self.test.model->getModelRunTime())];
}

- (void)updateProgress:(NSTimer *)timer {
    if ([self state] == RUNNING) {
        NSTimeInterval timeSinceStart = [[NSDate date] timeIntervalSinceDate:self.timerStartDate];
        NSTimeInterval timeLeft = self.test.model->getModelRunTime() - timeSinceStart;
        double minutesLeft = floor(timeLeft / 60);
        double secondsLeft = trunc(timeLeft - (minutesLeft * 60));
        
        [self.progressBar setProgress: (timeSinceStart / self.test.model->getModelRunTime()) animated:YES];
        [self.statusLabel setText:[NSString stringWithFormat:@"Analyzing [%02.0f:%02.0f]", minutesLeft, secondsLeft]];
        
        if (timeLeft <= 0.0) {
            NSLog(@"Camera state set to DONE");
            [self setState:DONE];
            
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}

- (void)endProcessing {
    /* Camera shutdown */
    [self.captureManager stopSession]; //AVCaptureSession stop capture
    [self.captureManager setSession: nil];
    [self.captureManager turnTorchOn:false];
    
    [self.statusLabel setText:@"Done."];

    /*
    // notification w/sound
    NSError* error;
#warning untested alert message
    NSURL *soundFile = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] URLForResource:@"Tock" withExtension:@"aiff"];
    self.alertSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFile error:&error];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Analysis completed."  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert setAlertViewStyle:UIAlertViewStyleDefault];
    
    [self.alertSound play];
    [alert show];
     */
    
    if ([self isTakingCalibrationPoint]) {
    //hessk: TODO: multi circle support
        self.test.model->calibrate(processor.getSamples()[0], self.calibrationValue, processor.getAverageStdDev());
        [self performSegueWithIdentifier:@"showCalibrationResults" sender:self];
    } else /* if (there are results) */ {
        self.result.value = self.test.model->evaluate(processor.getSamples()[0], processor.getAverageStdDev());
        self.result.stats = [NSString stringWithUTF8String:self.test.model->getStatData().c_str()];
        
        NSLog(self.result.stats);
        
        [self performSegueWithIdentifier:@"showResultsFromCamera" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showCalibrationResults"]) {
        [[segue destinationViewController] setTest:self.test];
    } else if ([[segue identifier] isEqualToString:@"showResultsFromCamera"]) {
        DataExporter exporter = DataExporter(self.test.model);
        exporter.exportDiagnosticRun();
        DataStore p = [[JKKDatabaseManager sharedInstance] openDatabase];
        // write results to database
        ResultEntry entry(-1, [self.result.name UTF8String], [self.result.subject UTF8String], [self.result.notes UTF8String], [self.result.date UTF8String], self.result.value, exporter.getCSVData(), exporter.getTextData(), [self.result.stats UTF8String]);
        
        self.result.resultID = p.insertResultEntry(entry);
        p.close();
        
        [[segue destinationViewController] setResult:self.result];
        [[segue destinationViewController] setSourceView:self];
    }
}

#pragma mark UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.alertSound stop];
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:NO];
}

#pragma mark - Protocol AVCaptureVideoDataOutputSampleBufferDelegate
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    /*
     * who owns this memory object(circles)? should it be defined in a broader scope? strarm 7.2.14
     */
    std::vector<cv::Vec3f> circles;
    
    
    
    /* Begin parseBuffer() from https://gist.github.com/jebai/8108287
     *
     */
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    
    //Processing here
    int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    float scaleX = bufferWidth / self.cameraOverlayView.frame.size.height; //short dimension [480/320=1.5] camera is rotated 90 from display axis
    float scaleY = bufferHeight / self.cameraOverlayView.frame.size.width; //long dimension
    int centerX = 0;
    int centerY = 0;
    int radius = 0;
    

    
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // put buffer in open cv, no memory copied
    cv::Mat mat = cv::Mat(bufferHeight,bufferWidth,CV_8UC4,pixel);
    
    /* 
     * Begin Occuchrome processing 
     */
    if ([self state] == RUNNING) {
        CameraLocation location = (CameraLocation)[defaults integerForKey:@"kCameraLocation"];
        switch (location) {
            case FRONT:
                centerX = self.test.model->getCircleCenterY()*scaleX;
                centerY = self.test.model->getCircleCenterX()*scaleY;
                break;
            case BACK:
                centerX = (self.test.model->getCircleCenterY()*scaleX);
                centerY = bufferHeight-(self.test.model->getCircleCenterX()*scaleY); //mirrored axis for some reason
                break;
            default:
                centerX = self.test.model->getCircleCenterY()*scaleX;
                centerY = self.test.model->getCircleCenterX()*scaleY;
                break;
        }
        radius = self.test.model->getCircleRadius()*(MIN(scaleX,scaleY));
        circles.push_back(cv::Vec3f(centerX, centerY, radius));
        //cv::cvtColor(mat, mat, CV_RGBA2BGR); //Is this really necessary? strarm 7.2.14
        processor.process(mat, circles);
    }
    /*  End processing 
     */
    
    
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    /* End parseBuffer()
     */
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraOverlayView updateCircleWithCenterX:self.test.model->getCircleCenterX() centerY:self.test.model->getCircleCenterY() radius:self.test.model->getCircleRadius() ];
    });

}
@end
