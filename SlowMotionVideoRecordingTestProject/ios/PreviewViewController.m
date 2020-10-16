//
//  PreviewViewController.m
//  SlowMotionVideoRecorder
//
//  Created by Raza on 10/1/20.
//  Copyright © 2020 Shuichi Tsutsumi. All rights reserved.
//

#import "PreviewViewController.h"
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PreviewViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonSelect;
@property (weak, nonatomic) IBOutlet UIButton *buttonRetake;
@property (nonatomic, weak) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;

@property AVPlayer *player;
@property AVPlayerItem *playerItem;
@property BOOL isPlaying;

@end

@implementation PreviewViewController

// MARK: - VIEW LIFE CYCLE

- (void)viewDidLoad {
  [super viewDidLoad];
  NSLog(@"%@", self.recordingURL);
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self setupView];
  
  NSLog(@"%f", [self getFrameRateFromAVPlayer]);
}

// MARK: - SETUP UI

-(void)setupView {
  
  //  self.playerItem = [[AVPlayerItem alloc] initWithURL:self.recordingURL];
  //  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
  //  self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
  //  AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  //  playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  //  playerLayer.frame = self.previewView.bounds;
  //  [self.previewView.layer addSublayer:playerLayer];
  //  [self.player play];
  //  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  //    [self.player pause];
  //  });
  
  //Output URL
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = paths.firstObject;
  NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeSlowMoVideo-%d.mov",arc4random() % 1000]];
  NSURL *url = [NSURL fileURLWithPath:myPathDocs];
  
  
  AVAsset *asset = [AVAsset assetWithURL:self.recordingURL];
  //Begin slow mo video export
  AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
  exporter.outputURL = url;
  exporter.outputFileType = AVFileTypeQuickTimeMovie;
  
  exporter.shouldOptimizeForNetworkUse = YES;
  
  [exporter exportAsynchronouslyWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      if (exporter.status == AVAssetExportSessionStatusCompleted) {
        NSURL *URL = exporter.outputURL;
        self.recordingURL = URL;
        NSLog(@"%@", URL.absoluteString);
        //        NSData *videoData = [NSData dataWithContentsOfURL:URL];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerLayer.frame = self.previewView.bounds;
        
        [self.previewView.layer addSublayer:playerLayer];
        [self.player play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [self.player pause];
        });
      }
    });
  }];
  
}

-(float)getFrameRateFromAVPlayer
{
  float fps=0.00;
  if (self.player.currentItem.asset) {
    AVAssetTrack * videoATrack = [[self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    if(videoATrack)
    {
      fps = videoATrack.nominalFrameRate;
    }
  }
  return fps;
}


// MARK: - BUTTON ACTIONS

- (IBAction)didTapRetakeButton:(UIButton *)sender {
  [self dismissViewControllerAnimated:YES completion:NULL];
}


- (IBAction)didTapSelectButton:(UIButton *)sender {
  [self dismissViewControllerAnimated:YES completion:^{
    [self.delegate didSelectVideoWithURL: self.recordingURL.absoluteString];
  }];
}

- (IBAction)didTapPlayPauseButton:(UIButton *)sender {
  if (self.isPlaying) {
    [self.player pause];
    [self.buttonPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
  } else {
    [self.buttonPlayPause setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
    [self.player setRate:0.0001];
  }
  self.isPlaying = !self.isPlaying;
}

// MARK: - HELPER METHODS

-(void)itemDidFinishPlaying:(NSNotification *) notification {
  // Will be called when AVPlayer finishes playing playerItem
  NSLog(@"AVPlayer finishes playing playerItem");
  self.isPlaying = NO;
  [self.buttonPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}


- (void)SlowMotion:(NSURL *)URl
{
  AVURLAsset* videoAsset = [AVURLAsset URLAssetWithURL:URl options:nil]; //self.inputAsset;
  
  AVAsset *currentAsset = [AVAsset assetWithURL:URl];
  AVAssetTrack *vdoTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  //create mutable composition
  AVMutableComposition *mixComposition = [AVMutableComposition composition];
  
  AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
  AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
  
  NSError *videoInsertError = nil;
  BOOL videoInsertResult = [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                          ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                                           atTime:kCMTimeZero
                                                            error:&videoInsertError];
  if (!videoInsertResult || nil != videoInsertError) {
    //handle error
    return;
  }
  
  NSError *audioInsertError =nil;
  BOOL audioInsertResult =[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                         ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                                          atTime:kCMTimeZero
                                                           error:&audioInsertError];
  
  if (!audioInsertResult || nil != audioInsertError) {
    //handle error
    return;
  }
  
  CMTime duration =kCMTimeZero;
  duration=CMTimeAdd(duration, currentAsset.duration);
  //slow down whole video by 2.0
  double videoScaleFactor = 2.0;
  CMTime videoDuration = videoAsset.duration;
  
  [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, videoDuration)
                             toDuration:CMTimeMake(videoDuration.value*videoScaleFactor, videoDuration.timescale)];
  [compositionAudioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, videoDuration)
                             toDuration:CMTimeMake(videoDuration.value*videoScaleFactor, videoDuration.timescale)];
  [compositionVideoTrack setPreferredTransform:vdoTrack.preferredTransform];
  
  NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *docsDir = [dirPaths objectAtIndex:0];
  NSString *outputFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"slowMotion.mov"]];
  if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
    [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
  NSURL *_filePath = [NSURL fileURLWithPath:outputFilePath];
  
  //export
  AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                       presetName:AVAssetExportPresetLowQuality];
  assetExport.outputURL=_filePath;
  assetExport.outputFileType =           AVFileTypeQuickTimeMovie;
  assetExport.shouldOptimizeForNetworkUse = YES;
  [assetExport exportAsynchronouslyWithCompletionHandler:^
   {
    
    switch ([assetExport status]) {
      case AVAssetExportSessionStatusFailed:
      {
        NSLog(@"Export session faiied with error: %@", [assetExport error]);
        dispatch_async(dispatch_get_main_queue(), ^{
          // completion(nil);
        });
      }
        break;
      case AVAssetExportSessionStatusCompleted:
      {
        
        NSLog(@"Successful");
        NSURL *outputURL = assetExport.outputURL;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
          
          [self writeExportedVideoToAssetsLibrary:outputURL];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          //                                            completion(_filePath);
        });
        
      }
        break;
      default:
        
        break;
    }
    
    
  }];
  
  
}

- (void)writeExportedVideoToAssetsLibrary :(NSURL *)url {
  NSURL *exportURL = url;
  ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
  if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL]) {
    [library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error){
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                              message:[error localizedRecoverySuggestion]
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
          [alertView show];
        }
        if(!error)
        {
          // [activityView setHidden:YES];
          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sucess"
                                                              message:@"video added to gallery successfully"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
          [alertView show];
        }
#if !TARGET_IPHONE_SIMULATOR
        [[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
#endif
      });
    }];
  } else {
    NSLog(@"Video could not be exported to assets library.");
  }
  
}

//  AVAsset *asset = [AVAsset assetWithURL:self.recordingURL];
//
//  //Begin slow mo video export
//  AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
//  exporter.outputURL = self.recordingURL;
//  exporter.outputFileType = AVFileTypeQuickTimeMovie;
//  exporter.shouldOptimizeForNetworkUse = YES;
//
//  [exporter exportAsynchronouslyWithCompletionHandler:^{
//    dispatch_async(dispatch_get_main_queue(), ^{
//      if (exporter.status == AVAssetExportSessionStatusCompleted) {
//        NSURL *URL = exporter.outputURL;
////        NSData *videoData = [NSData dataWithContentsOfURL:URL];
//          AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
//          [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
//          self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
//          AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//          playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//          playerLayer.frame = self.previewView.bounds;
//
//          [self.previewView.layer addSublayer:playerLayer];
//      }
//    });
//  }];


//PHVideoRequestOptions *options = [PHVideoRequestOptions new];
//       options.networkAccessAllowed = YES;
//       [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
//           if(([asset isKindOfClass:[AVComposition class]] && ((AVComposition *)asset).tracks.count == 2)){
//               //Added by UD for slow motion videos. See Here: https://overflow.buffer.com/2016/02/29/slow-motion-video-ios/
//
//               //Output URL
//               NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//               NSString *documentsDirectory = paths.firstObject;
//               NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeSlowMoVideo-%d.mov",arc4random() % 1000]];
//               NSURL *url = [NSURL fileURLWithPath:myPathDocs];
//
//               //Begin slow mo video export
//               AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
//               exporter.outputURL = url;
//               exporter.outputFileType = AVFileTypeQuickTimeMovie;
//               exporter.shouldOptimizeForNetworkUse = YES;
//
//               [exporter exportAsynchronouslyWithCompletionHandler:^{
//                   dispatch_async(dispatch_get_main_queue(), ^{
//                       if (exporter.status == AVAssetExportSessionStatusCompleted) {
//                           NSURL *URL = exporter.outputURL;
//                           self.filePath=URL.absoluteString;
//
//
//                          NSURLsession *uploadTask=[manager uploadTaskWithRequest:request
//                                          fromFile:[NSURL URLWithString:self.filePath]
//                                          progress:nil
//                                 completionHandler:nil];
//
//
//
//
//                        //Use above method or use the below one.
//
//
//                           // NSData *videoData = [NSData dataWithContentsOfURL:URL];
//                           //
//                           //// Upload
//                           //[self uploadSelectedVideo:video data:videoData];
//                       }
//                   });
//               }];
//
//
//           }
//       }];


@end
