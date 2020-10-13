//
//  PreviewViewController.h
//  SlowMotionVideoRecorder
//
//  Created by Raza on 10/1/20.
//  Copyright © 2020 Shuichi Tsutsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PreviewViewControllerProtocol <NSObject>

-(void)didSelectVideoWithURL:(NSString *_Nullable) url;

@end

NS_ASSUME_NONNULL_BEGIN

@interface PreviewViewController : UIViewController

@property NSURL* recordingURL;
@property(nonatomic,weak) id <PreviewViewControllerProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
