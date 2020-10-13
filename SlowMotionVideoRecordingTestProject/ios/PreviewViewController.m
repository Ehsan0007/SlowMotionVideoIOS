//
//  PreviewViewController.m
//  SlowMotionVideoRecorder
//
//  Created by Raza on 10/1/20.
//  Copyright © 2020 Shuichi Tsutsumi. All rights reserved.
//

#import "PreviewViewController.h"
#import <AVKit/AVKit.h>

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

  self.playerItem = [[AVPlayerItem alloc] initWithURL:self.recordingURL];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
  self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
  AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  playerLayer.frame = self.previewView.bounds;
  [self.previewView.layer addSublayer:playerLayer];
  [self.player pause];
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


@end
