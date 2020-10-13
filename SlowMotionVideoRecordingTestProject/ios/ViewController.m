//
//  ViewController.m
//  SlowMotionVideoRecorder
//
//  Created by shuichi on 12/17/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"
#import "TTMCaptureManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "PreviewViewController.h"
#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>


@interface ViewController ()
<TTMCaptureManagerDelegate, PreviewViewControllerProtocol>
{
  NSTimeInterval startTime;
  BOOL isNeededToSave;
}
@property (nonatomic, strong) TTMCaptureManager *captureManager;
@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, strong) UIImage *recStartImage;
@property (nonatomic, strong) UIImage *recStopImage;
@property (nonatomic, strong) UIImage *outerImage1;
@property (nonatomic, strong) UIImage *outerImage2;

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *fpsControl;
@property (nonatomic, weak) IBOutlet UIButton *recBtn;
@property (nonatomic, weak) IBOutlet UIImageView *outerImageView;
@property (nonatomic, weak) IBOutlet UIView *previewView;
@end


@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.captureManager = [[TTMCaptureManager alloc] initWithPreviewView:self.previewView
                                                   preferredCameraType:CameraTypeBack
                                                            outputMode:OutputModeVideoData];
  self.captureManager.delegate = self;
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleDoubleTap:)];
  tapGesture.numberOfTapsRequired = 2;
  [self.view addGestureRecognizer:tapGesture];
  
  
  // Setup images for the Shutter Button
  UIImage *image;
  image = [UIImage imageNamed:@"ShutterButtonStart"];
  self.recStartImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.recBtn setImage:self.recStartImage
               forState:UIControlStateNormal];
  
  image = [UIImage imageNamed:@"ShutterButtonStop"];
  self.recStopImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  
  [self.recBtn setTintColor:[UIColor colorWithRed:245./255.
                                            green:51./255.
                                             blue:51./255.
                                            alpha:1.0]];
  self.outerImage1 = [UIImage imageNamed:@"outer1"];
  self.outerImage2 = [UIImage imageNamed:@"outer2"];
  self.outerImageView.image = self.outerImage1;
  
  [self.captureManager switchFormatWithDesiredFPS:180.0]; // Static FPS set
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self.captureManager updateOrientationWithPreviewView:self.previewView];
}


// =============================================================================
#pragma mark - Gesture Handler

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
  [self.captureManager toggleContentsGravity];
}


// =============================================================================
#pragma mark - Private


- (void)saveRecordedFile:(NSURL *)recordedFile {
  
  [SVProgressHUD showWithStatus:@"Saving..."
                       maskType:SVProgressHUDMaskTypeGradient];
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:recordedFile];
    } completionHandler:^(BOOL success, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD dismiss];
        
        NSString *title;
        NSString *message;
        
        if (!success) {
          
          title = @"Failed to save video";
          message = [error localizedDescription];
        }
        else {
          title = @"Saved!";
          message = nil;
        }
        
        NSLog(@"title %@, Message: %@", title, message);
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
//                                                        message:message
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
////        [alert show];
      });
      
      if (success) {
        NSLog(@"Success");
      }
      else {
        NSLog(@"write error : %@",error);
      }
    }];
    
    //        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    //        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:recordedFile
    //                                         completionBlock:
    //         ^(NSURL *assetURL, NSError *error) {
    //
    //             dispatch_async(dispatch_get_main_queue(), ^{
    //
    //                 [SVProgressHUD dismiss];
    //
    //                 NSString *title;
    //                 NSString *message;
    //
    //                 if (error != nil) {
    //
    //                     title = @"Failed to save video";
    //                     message = [error localizedDescription];
    //                 }
    //                 else {
    //                     title = @"Saved!";
    //                     message = nil;
    //                 }
    //
    //                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
    //                                                                 message:message
    //                                                                delegate:nil
    //                                                       cancelButtonTitle:@"OK"
    //                                                       otherButtonTitles:nil];
    //                 [alert show];
    //             });
    //            NSLog(@"%@", assetURL);
    //         }];
  });
}



// =============================================================================
#pragma mark - Timer Handler

- (void)timerHandler:(NSTimer *)timer {
  
  NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
  NSTimeInterval recorded = current - startTime;
  
  self.statusLabel.text = [self stringFromTimeInterval:recorded]; //[NSString stringWithFormat:@"%.2f", recorded];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger interval = timeInterval;
//    NSInteger ms = (fmod(timeInterval, 1) * 1000);
    long seconds = interval % 60;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);

  //@"%0.2ld:%0.2ld:%0.2ld,%0.3ld"
    return [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld", hours, minutes, seconds];
}


//func stringFromTimeInterval(interval: TimeInterval) -> NSString {
//
//  let ti = NSInteger(interval)
//
//  let ms = Int((interval % 1) * 1000)
//
//  let seconds = ti % 60
//  let minutes = (ti / 60) % 60
//  let hours = (ti / 3600)
//
//  return NSString(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
//}


// =============================================================================
#pragma mark - AVCaptureManagerDeleagte

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
  
  //    LOG_CURRENT_METHOD;
  
  if (error) {
    NSLog(@"error:%@", error);
    return;
  }
  
  if (!isNeededToSave) {
    return;
  }
  
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  PreviewViewController *vc = [sb instantiateViewControllerWithIdentifier:@"PreviewViewController"];
  vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  vc.recordingURL = outputFileURL;
  vc.delegate = self;
  [self presentViewController:vc animated:YES completion:NULL];
  
//  AVPlayer *player = [AVPlayer playerWithURL:outputFileURL];
//  AVPlayerViewController *playerViewController = [AVPlayerViewController new];
//  player.rate = 0.01;
//  playerViewController.player = player;
//  
//  [self presentViewController:playerViewController animated:YES completion:^{
//      [playerViewController.player play];
//  }];
  
    [self saveRecordedFile:outputFileURL];
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)recButtonTapped:(id)sender {
  
  // REC START
  if (!self.captureManager.isRecording) {
    
    // change UI
    [self.recBtn setImage:self.recStopImage
                 forState:UIControlStateNormal];
    self.fpsControl.enabled = NO;
    
    // timer start
    startTime = [[NSDate date] timeIntervalSince1970];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(timerHandler:)
                                                userInfo:nil
                                                 repeats:YES];
    
    [self.captureManager startRecording];
  }
  // REC STOP
  else {
    
    isNeededToSave = YES;
    [self.captureManager stopRecording];
    
    [self.timer invalidate];
    self.timer = nil;
    
    // change UI
    [self.recBtn setImage:self.recStartImage
                 forState:UIControlStateNormal];
    self.fpsControl.enabled = YES;
  }
}

//- (IBAction)retakeButtonTapped:(id)sender {
//    
//    isNeededToSave = NO;
//    [self.captureManager stopRecording];
//
//    [self.timer invalidate];
//    self.timer = nil;
//    
//    self.statusLabel.text = nil;
//}

- (IBAction)fpsChanged:(UISegmentedControl *)sender {
  
  // Switch FPS
  
  CGFloat desiredFps = 0.0;;
  switch (self.fpsControl.selectedSegmentIndex) {
    case 0:
    default:
    {
      break;
    }
    case 1:
      desiredFps = 60.0;
      break;
    case 2:
      //            desiredFps = 240.0;
      desiredFps = 180.0;
      break;
  }
  
  
  [SVProgressHUD showWithStatus:@"Switching..."
                       maskType:SVProgressHUDMaskTypeGradient];
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    if (desiredFps > 0.0) {
      [self.captureManager switchFormatWithDesiredFPS:desiredFps];
    }
    else {
      [self.captureManager resetFormat];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      if (desiredFps >= 120.0) {
        self.outerImageView.image = self.outerImage2;
      }
      else {
        self.outerImageView.image = self.outerImage1;
      }
      [SVProgressHUD dismiss];
    });
  });
}

- (IBAction)didTapBackButton:(UIButton *)sender {
  [self dismissViewControllerAnimated:YES completion:^{
    [self.delegate didTapBackButton];
  }];
}


// MARK: - PREVIEW VIEW CONTROLLER PROTOCOL IMPLEMENTATION

- (void)didSelectVideoWithURL:(NSString *)url {
  [self dismissViewControllerAnimated:YES completion:^{
    [self.delegate didSelectVideoWithURL:url];
  }];
}


@end
