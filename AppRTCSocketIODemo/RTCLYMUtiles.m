//
//  RTCLYMUtiles.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "RTCLYMUtiles.h"
#import <AVFoundation/AVFoundation.h>


@implementation RTCLYMUtiles

-(BOOL)openAuthersOfCarmarWithOptBlock:(void (^)(BOOL))isOpen{
    /******************权限获取判断*****************/
    
    //摄像头
    NSString *mediaType = AVMediaTypeVideo;// Or AVMediaTypeAudio
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    //    NSLog(@"---cui--authStatus--------%ld",authStatus);
    // This status is normally not visible—the AVCaptureDevice class methods for discovering devices do not return devices the user is restricted from accessing.
    if(authStatus ==AVAuthorizationStatusRestricted){
        //        NSLog(@"Restricted");
        isOpen(NO);
    }else if(authStatus == AVAuthorizationStatusDenied){
        // The user has explicitly denied permission for media capture.
        NSLog(@"Denied");     //应该是这个，如果不允许的话
        
        isOpen(NO);
    }
    else if(authStatus == AVAuthorizationStatusAuthorized){//允许访问
        // The user has explicitly granted permission for media capture, or explicit user permission is not necessary for the media type in question.
        NSLog(@"Authorized");
        // 有摄像头权限后判断一下麦克风的权限
        isOpen(YES);
    }else if(authStatus == AVAuthorizationStatusNotDetermined){
        // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted){//点击允许访问时调用
                //用户明确许可与否，媒体需要捕获，但用户尚未授予或拒绝许可。
                NSLog(@" hosten Granted access to %@", mediaType);
                if (isOpen) {
                    isOpen(YES);
                }
            }
            else {
                NSLog(@"hosten  Not granted access to %@", mediaType);
                if (isOpen) {
                    isOpen(NO);
                }
            }
            
        }];
        
    }else {
        NSLog(@"Unknown authorization status");
        return NO;
    }
    return NO;
}

-(void)openAuthersOfMICWithBlock:(void (^)(BOOL))open{
    //麦克风
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            if (open) {
                open(YES);
            }
        } else {
            NSLog(@"hosten  Not granted access to requestRecordPermission");
            if (open) {
                open(NO);
            }
        }
    }];
    
}
@end
