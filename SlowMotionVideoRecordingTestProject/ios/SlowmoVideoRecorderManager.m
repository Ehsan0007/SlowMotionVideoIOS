//
//  SlowmoVideoRecorderManager.m
//  SlowMotionVideoRecordingTestProject
//
//  Created by Raza on 10/12/20.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import "SlowmoVideoRecorderManager.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>


@interface SlowmoVideoRecorderManager () <ViewControllerProtocol>

@property (nonatomic, strong) RCTResponseSenderBlock callback;

@end


@implementation SlowmoVideoRecorderManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(launchSlowmoVideoRecorder: (RCTResponseSenderBlock)callBack) {
  
  self.callback = callBack;
  dispatch_async(dispatch_get_main_queue(), ^{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ViewController"];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    vc.delegate = self;
    UIViewController *root = RCTPresentedViewController();
    [root presentViewController:vc animated:YES completion:NULL];
  });
  
}



// MARK: - VIEWCONTROLLER PROTOCOL IMPLEMENTATION

- (void)didTapBackButton {
  self.callback(@[@{@"didCancel": @YES}]);
}

- (void)didSelectVideoWithURL:(NSString *)url {
  self.callback(@[@{@"didSelectVideoWithURL": url}]);
}



@end
