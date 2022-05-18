//
//  RTCPeerConnectionManager.h
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/11.
//

#import <UIKit/UIKit.h>

#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCVideoTrack.h>
/** Represents the ice connection state of the peer connection. */
typedef NS_ENUM(NSInteger, RTCManagerIceConnectionState) {
    RTCManagerIceConnectionStateNew,
    RTCManagerIceConnectionStateChecking,
  RTCManagerIceConnectionStateConnected,
  RTCManagerIceConnectionStateCompleted,
  RTCManagerIceConnectionStateFailed,
  RTCManagerIceConnectionStateDisconnected,
  RTCManagerIceConnectionStateClosed,
  RTCManagerIceConnectionStateCount,
};
typedef NS_ENUM(NSInteger,RTCAudioSessionDeviceType) {
    RTCAudioSessionDeviceTypeEarphone      = 1,//听筒
    RTCAudioSessionDeviceTypeSpeaker       = 2,//外放
    RTCAudioSessionDeviceTypeBluetooth     = 3,//蓝牙
    RTCAudioSessionDeviceTypeHeadsetMic    = 4,//HeadsetMic 耳机(线控)
};
@class RTCPeerConnectionManager;
NS_ASSUME_NONNULL_BEGIN
@protocol  RTCPeerConnectionManagerDelegate <NSObject>
- (void)peerConnectionManager:(RTCPeerConnectionManager*)client
            didChangeIceState:(RTCManagerIceConnectionState)state;

- (void)peerConnectionManager:(RTCPeerConnectionManager*)client
      didGenerateIceCandidate:(NSString*)candidateStr
                sdpMLineIndex:(int)sdpMLineIndex
                       sdpMid:(NSString*)sdpMid;

@end
@interface RTCPeerConnectionManager : UIView
@property(nonatomic, weak) id<RTCPeerConnectionManagerDelegate> delegate;
-(instancetype)initWithUserDataChannal:(BOOL)useDataChannal;
- (void)startRTCWithIsOffer:(BOOL)isOffer offerSdp:(nullable RTCSessionDescription *)sessionDesc Handler:(void(^)(RTCSessionDescription *_Nullable sessionDesc,RTCCameraVideoCapturer *_Nullable cameraCapture,NSError *error)) handler;
- (void)setRemoteSDPWithSDP:(NSString *)sdp;
- (void)addRemoteIceCandidateWithCandidate:(NSString*)candidateStr sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid;


/**
 视频本地渲染窗口

 @param localeView 窗口
 */
- (void)addLocalView:(UIView *_Nonnull)localeView;

/**
 远端视频渲染窗口

 @param remoteView 视频渲染窗口
 @param userId  扩展参数
 */
- (void)addRemoteView:(UIView *_Nonnull)remoteView userID:(NSString *_Nullable)userId;

/// 切换音频设备
/// @param deviceType  枚举类型切换 默认外音
-(NSString *)switchAudioDeviceWithDeviceType:(RTCAudioSessionDeviceType)deviceType;

/**
 数据通道发送消息功能

 @param msg 消息文本
 @return 是否发送成功
 */
- (BOOL)sendMessage:(NSString*)msg;
/**
 数据通道发送消息功能
 
 @param data 消息二进制
 @return 是否发送成功
 */
- (BOOL)sendData:(NSData *)data;
- (void)getStatesWithCallBack:(void (^)( NSDictionary<NSString*,id>* dataCb))statesCB;


- (void)close;
@end

NS_ASSUME_NONNULL_END
