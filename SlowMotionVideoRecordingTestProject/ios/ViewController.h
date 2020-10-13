//
//  ViewController.h
//  SlowMotionVideoRecorder
//
//  Created by shuichi on 12/17/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ViewControllerProtocol <NSObject>

-(void)didSelectVideoWithURL:(NSString *_Nullable) url;
-(void)didTapBackButton;

@end

@interface ViewController : UIViewController

@property(nonatomic,weak) id <ViewControllerProtocol> _Nullable delegate;

@end
