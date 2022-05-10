//
//  RTCCameraVideoCapturer.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "RTCLYMCameraVideoCapturer.h"
#include <WebRTC/RTCCameraVideoCapturer.h>
#include <WebRTC/RTCFileVideoCapturer.h>

API_AVAILABLE(ios(10))
@interface RTCLYMCameraVideoCapturer()
@property(nonatomic,strong)RTCCameraVideoCapturer *capturer;
@property(nonatomic,assign)int fps;
@property(nonatomic,assign)int windth;
@property(nonatomic,assign)int height;
@property(nonatomic, assign) BOOL usingFrontCamera;

@property(nonatomic, strong) RTCFileVideoCapturer *fileVideoCapture;
@end
@implementation RTCLYMCameraVideoCapturer
- (instancetype _Nullable )initWithCapturer:(RTCCameraVideoCapturer *_Nonnull)capturer{
    if (self = [super init]) {
        _capturer = capturer;
        //      __weak typeof(self) weakSelf = self;
        //      [self.capturer onOutputSampleBufferCB:^(AVCaptureOutput * _Nonnull captureOutput, CMSampleBufferRef  _Nonnull sampleBuffer, AVCaptureConnection * _Nonnull connection) {
        //          [weakSelf.capturer ouputSampleWithcaptureOutput:captureOutput didOutputPixelBuffer:nil fromConnection:connection SampleBuffer:sampleBuffer];
        //      }];
        _usingFrontCamera = YES;
    }
    
    return self;
}
- (instancetype _Nullable )initWithFileCapturer:(RTCFileVideoCapturer *_Nonnull)capturer{
    if (self = [super init]) {
       _fileVideoCapture = capturer;
    }
    
    return self;
}

- (void)startCaptureWithFileNamed:(NSString*_Nonnull)fileName{
    if (_fileVideoCapture) {
        [_fileVideoCapture startCapturingFromFileNamed:fileName onError:^(NSError * _Nonnull error) {
            NSLog(@"");
        }];
    }
}
- (void)stopCapture{
    if (_fileVideoCapture) {
        [_fileVideoCapture stopCapture];
        return;
    }
    [self stopCaptureWitCcompletionHandler:^{
        
    }];
}
- (void)switchCamera{
    if (_fileVideoCapture) {
        return;
    }
    [self switchCameraWitCcompletionHandler:^(NSError * _Nullable error) {
        
    }];
}

- (void)startCaptureWithFPS:(NSInteger)fps width:(int)width height:(int)height completionHandler:(nullable void(^)(NSError * _Nullable error))competionHanler{
    if (_fileVideoCapture) {
        return;
    }
    self.fps = fps;
    self.windth = width;
    self.height = height;
    AVCaptureDevicePosition position =
    _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self findDeviceForPosition:position];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device width:width height:height];
    
    NSInteger fpsI = 30;
    if (fps > 0) {
        fpsI = fps;
    }else{
        fpsI = [self selectFpsForFormat:format];
    }
    
    //  [_capturer startCaptureWithDevice:device format:format fps:fpsI];
    [_capturer startCaptureWithDevice:device format:format fps:fpsI completionHandler:competionHanler];
}
- (void)stopCaptureWitCcompletionHandler:(nullable void(^)(void))competionHanler{
    if (_fileVideoCapture) {
        return;
    }
    [_capturer stopCaptureWithCompletionHandler:competionHanler];

}
- (void)switchCameraWitCcompletionHandler:(nullable void(^)(NSError * _Nullable error))competionHanler{
    if (_fileVideoCapture) {
        return;
    }
    _usingFrontCamera = !_usingFrontCamera;
    int widthT = _windth;
    int heightT = _height;
    if (!_usingFrontCamera) {
        widthT = _windth*2;
        heightT = _height*2;
    }
    [self startCaptureWithFPS:_fps width:widthT height:heightT completionHandler:competionHanler];
}
#pragma mark - Private

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device width:(CGFloat)width height:(CGFloat)height{
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    int targetWidth = width;
    int targetHeight = height;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        }
    }
    
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    return selectedFormat;
}

- (NSInteger)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
    Float64 maxFramerate = 0;
    for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
        maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
    }
    return maxFramerate;
}
-(void)dealloc{
    NSLog(@"ARDCaptureController dealloc()");
}
@end
