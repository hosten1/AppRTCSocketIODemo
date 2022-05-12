//
//  RTCCameraVideoCapturer.h
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import <Foundation/Foundation.h>


@class RTCCameraVideoCapturer;
@class RTCFileVideoCapturer;


NS_ASSUME_NONNULL_BEGIN

@interface RTCLYMCameraVideoCapturer : NSObject
@property(nonatomic,readonly)RTCCameraVideoCapturer *capturer;

- (instancetype _Nullable )initWithCapturer:(RTCCameraVideoCapturer *_Nonnull)capturer;
- (instancetype _Nullable )initWithFileCapturer:(RTCFileVideoCapturer *_Nonnull)capturer API_AVAILABLE(ios(10));
- (void)startCaptureWithFileNamed:(NSString*_Nonnull)fileName;
- (void)stopCapture;
- (void)switchCamera;

- (void)startCaptureWithFPS:(NSInteger)fps width:(int)width height:(int)height completionHandler:(nullable void(^)(NSError * _Nullable error))competionHanler;
- (void)stopCaptureWitCcompletionHandler:(nullable void(^)(void))competionHanler;
- (void)switchCameraWitCcompletionHandler:(nullable void(^)(NSError * _Nullable error))competionHanler;
@end

NS_ASSUME_NONNULL_END
