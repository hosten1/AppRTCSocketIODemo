//
//  RTCPeerConnectionManager.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/11.
//

#import "RTCPeerConnectionManager.h"
#import <WebRTC/WebRTC.h>

#ifndef WEAKSELF
#define WEAKSELF __weak __typeof(&*self)weakSelf = self;
#endif
#ifndef STRONGSELF
#define STRONGSELF __strong __typeof(&*weakSelf)strongSelf = weakSelf;
#endif
#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
block();\
} else {\
dispatch_async(queue, block);\
}
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";
static NSString * const kARDScreenVideoTrackId = @"ARDAMSv1";
static NSString * const kARDMediaStreamId = @"ARDAMS";

typedef NS_ENUM(NSInteger,RTCAudioSessionDeviceType) {
    RTCAudioSessionDeviceTypeEarphone      = 1,//听筒
    RTCAudioSessionDeviceTypeSpeaker       = 2,//外放
    RTCAudioSessionDeviceTypeBluetooth     = 3,//蓝牙
    RTCAudioSessionDeviceTypeHeadsetMic    = 4,//HeadsetMic 耳机(线控)
};
@interface RTCPeerConnectionManager ()<RTCPeerConnectionDelegate,RTCAudioSessionDelegate,RTCDataChannelDelegate,RTCEAGLVideoViewDelegate>
// 是不是主叫
@property(nonatomic, strong)RTCPeerConnection *peerconnetion;
@property(nonatomic, strong)RTCPeerConnectionFactory *peerconnetionFact;
@property(nonatomic, strong)RTCCameraVideoCapturer *cameraCapture;

@property(nonatomic, strong) RTCCameraPreviewView *localeVideoView;
@property(nonatomic, strong) RTCEAGLVideoView *remoteVideoView;

@property(nonatomic, strong)RTCDataChannel *sendDC ;
@property(nonatomic, strong)RTCAudioTrack *localAudioTrack;
@property(nonatomic, strong)RTCVideoTrack *localVideoTrack;
@property(nonatomic, strong)RTCVideoTrack *remoteVideoTrack;

@property(nonatomic, assign) BOOL isOffer ;
@property(nonatomic, strong)NSMutableArray<RTCIceCandidate*>* cacheCandidateMsg;
@property(nonatomic, copy) NSString* selfid;
@property(nonatomic, assign) BOOL isSetRemote;

@property (strong,nonatomic)  RTCAudioSession *audioSession;

@property(nonatomic, assign) CGSize remoteVideoSize;
@end

@implementation RTCPeerConnectionManager
-(instancetype)init{
    if (self = [super init]) {
        _cacheCandidateMsg = [NSMutableArray array];
    }
    return self;
}
-(RTCPeerConnectionFactory *)peerconnetionFact{
    if (!_peerconnetionFact) {
        RTCInitializeSSL();
        NSDictionary *fieldTrials = @{};
        RTCInitFieldTrialDictionary(fieldTrials);
        RTCDefaultVideoDecoderFactory *decodeFact = [[RTCDefaultVideoDecoderFactory alloc]init];
        RTCDefaultVideoEncoderFactory *encodeFact = [[RTCDefaultVideoEncoderFactory alloc]init];
        encodeFact.preferredCodec = [[RTCVideoCodecInfo alloc]initWithName:kRTCVideoCodecVp8Name];
        _peerconnetionFact = [[RTCPeerConnectionFactory alloc]initWithEncoderFactory:encodeFact decoderFactory:decodeFact];
    }
    return _peerconnetionFact;
}


- (RTCMediaConstraints *)_defaultPeerConnectionConstraints {
    NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement" :kRTCMediaConstraintsValueTrue};
    
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}
-(RTCAudioTrack*)audioTrack{
    //如果已经建立过本地音频资源则不再采集
    NSDictionary *mandatoryConstraints = @{};
    //    NSDictionary *optionalConstraints = @{@"googEchoCancellation":@"true",@"googAutoGainControl":@"false",@"googNoiseSuppression":@"false"};
    //    ,@"ios_force_software_aec_HACK"
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                                                             optionalConstraints:nil];
    RTCAudioSource *source = [_peerconnetionFact audioSourceWithConstraints:constraints];
    return [_peerconnetionFact audioTrackWithSource:source trackId:kARDAudioTrackId];
}
-(RTCVideoTrack*)videoTrack{
    RTCVideoSource *source = [_peerconnetionFact videoSource];
    // 这里设置采集的分辨率和码率
    [source adaptOutputFormatToWidth:640 height:480 fps:30];
    return [_peerconnetionFact videoTrackWithSource:source trackId:kARDVideoTrackId];
}

- (void)startRTCWithIsOffer:(BOOL)isOffer offerSdp:(RTCSessionDescription *)sessionDesc Handler:(nonnull void (^)(RTCSessionDescription * _Nullable, RTCCameraVideoCapturer * _Nullable, NSError * _Nonnull))handler{
    self.isOffer = isOffer;
    RTCConfiguration *config = [[RTCConfiguration alloc]init];
    RTCIceServer *iceserver = [[RTCIceServer alloc]initWithURLStrings:@[@"turn:www.lymggylove.top:3478"] username:@"lym" credential:@"123456"];
    config.iceServers = @[iceserver];
//    config.bundlePolicy = RTCBundlePolicyMaxBundle;
    //    config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
//    config.iceTransportPolicy = RTCIceTransportPolicyAll;
//    config.sdpSemantics = RTCSdpSemanticsPlanB;
//    config.tcpCandidatePolicy = RTCTcpCandidatePolicyDisabled;
//    config.continualGatheringPolicy = RTCContinualGatheringPolicyGatherContinually;
//    config.disableIPV6 = NO;
    //  这个参数必须设置
    config.logFilePath  = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] mutableCopy] stringByAppendingString:@"/log/"];
    RTCMediaConstraints *constraints =  [self _defaultPeerConnectionConstraints];
    if (!self.peerconnetionFact) {
        return;
    }
    NSAssert(self.peerconnetionFact, @"peerConnectionFactory is null ");
    self.peerconnetion  = [self.peerconnetionFact peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    NSAssert(_peerconnetion, @"peerConnection is null");
//    RTCDataChannelConfiguration *configDC = [[RTCDataChannelConfiguration alloc]init];
//    configDC.channelId = 0;
//    configDC.isNegotiated = true;
//    self.sendDC = [_peerconnetion dataChannelForLabel:@"my channal" configuration:configDC];
//    NSAssert(_sendDC, @"RTCDatachannal is null");
//    _sendDC.delegate = self;
    self.localVideoTrack = [self videoTrack];
    // WebRTC中封装的摄像头采集
    RTCCameraVideoCapturer *cameraCapture = [[RTCCameraVideoCapturer alloc]initWithDelegate:_localVideoTrack.source];
    self.cameraCapture = cameraCapture;

    [self.peerconnetion addTrack:_localVideoTrack streamIds:@[kARDMediaStreamId]];
    _localVideoTrack.isEnabled = true;
    self.localAudioTrack = [self audioTrack];
    [self.peerconnetion addTrack:_localAudioTrack streamIds:@[kARDMediaStreamId]];
    if (_isOffer) {
        RTCMediaConstraints *constraints = [self defaultOfferConstraints];
        WEAKSELF
        [self.peerconnetion offerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            if (!error) {
                STRONGSELF
                // 发送出去
                if (handler) {
                    handler(sdp,cameraCapture,error);
                }
                [strongSelf.peerconnetion setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                    if (handler) {
                        handler(nil,nil,error);
                    }
                    if (!error) {
                        // 如果本地view已经添加 则直接添加显示
                        if (weakSelf.localeVideoView) {
                            dispatch_main_async_safe(^{
                                weakSelf.localeVideoView.captureSession = weakSelf.cameraCapture.captureSession;

                            });
                        }
                    }
                }];
                
            }else{
                if (handler) {
                    handler(nil,nil,error);
                }
            }
        }];
        
    }else{
       
        WEAKSELF
        [self.peerconnetion setRemoteDescription:sessionDesc completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                STRONGSELF
                strongSelf.isSetRemote = YES;
                [strongSelf _addcandidateFUN];
                RTCMediaConstraints *constraints = [strongSelf defaultAnswerConstraints];
                [strongSelf.peerconnetion answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                    if (!error) {
                        if (handler) {
                            handler(sdp,cameraCapture,error);
                        }
                        [weakSelf.peerconnetion setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                            if (handler) {
                                handler(nil,cameraCapture,error);
                            }
                            if (!error) {
                                // 如果本地view已经添加 则直接添加显示
                                if (weakSelf.localeVideoView) {
                                    dispatch_main_async_safe(^{
                                        weakSelf.localeVideoView.captureSession = weakSelf.cameraCapture.captureSession;

                                    });
                                }
                            }
                        }];
                    }else{
                        if (handler) {
                            handler(nil,cameraCapture,error);
                        }
                    }
                }];
            }else{
                if (handler) {
                    handler(nil,cameraCapture,error);
                }
            }
        }];
    }
   
    
}
-(void)setRemoteSDPWithSDP:(NSString *)sdp{
    RTCSessionDescription *anserSession = [[RTCSessionDescription alloc]initWithType:RTCSdpTypeAnswer sdp:sdp];
    [_peerconnetion setRemoteDescription:anserSession completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"============> setremote %@",error.localizedDescription);
            
        }
    }];
    self.isSetRemote = YES;
    [self _addcandidateFUN];
}
- (void)addRemoteIceCandidateWithCandidate:(NSString*)candidateStr sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid{
    NSAssert(candidateStr, @"sdp is null");
    NSAssert(sdpMid, @"sdpMid is null");
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc]initWithSdp:candidateStr sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
    if (_isSetRemote == true) {
        // 先把换存的遍历设置
        [self _addcandidateFUN];
        //然后添加到peer里
        [self.peerconnetion addIceCandidate:candidate];
    } else {
//        添加到缓存里
        [self.cacheCandidateMsg addObject:candidate];
    }
}
- (void)addLocalView:(UIView *)localeView{

    if (!_localeVideoView) {
        self.localeVideoView = [[RTCCameraPreviewView alloc]init];
        _localeVideoView.backgroundColor = [UIColor blackColor];
        _localeVideoView.frame = CGRectMake(0, 0, localeView.bounds.size.width,localeView.bounds.size.height);
        _localeVideoView.hidden = NO;
        [localeView insertSubview:_localeVideoView atIndex:0];
        
    }
    // 如果已经有catpure了 就添加显示
    if (_cameraCapture) {
        _localeVideoView.captureSession = _cameraCapture.captureSession;
    }

}
-(void)addRemoteView:(UIView *)remoteView userID:(NSString *)userId{
    if (!_remoteVideoView) {
        self.remoteVideoView = [[RTCEAGLVideoView alloc]init];
        _remoteVideoView.backgroundColor = [UIColor blackColor];
        _remoteVideoView.frame = CGRectMake(0,0, remoteView.bounds.size.width, remoteView.bounds.size.height);
        [remoteView insertSubview:_remoteVideoView atIndex:0];
        
    }
    if (_remoteVideoTrack) {
        [_remoteVideoTrack addRenderer:_remoteVideoView];
    }
    // 如果缓存有变化的大小就更新下
    if (_remoteVideoSize.width > 0) {
        [self updateVideoViewFrameWithchangeVideoView:_remoteVideoView changeToSize:_remoteVideoSize];
    }

}
- (void)_addcandidateFUN {
    for (RTCIceCandidate *candidate in _cacheCandidateMsg) {
        [self.peerconnetion addIceCandidate:candidate];
    }
    [self.cacheCandidateMsg removeAllObjects];
}
- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}
- (RTCMediaConstraints *)defaultOfferConstraints {
    
    NSMutableDictionary *mandatoryConstraints = [NSMutableDictionary dictionary];
    
    [mandatoryConstraints setObject:kRTCMediaConstraintsValueTrue forKey:kRTCMediaConstraintsOfferToReceiveAudio];
    [mandatoryConstraints setObject:kRTCMediaConstraintsValueTrue forKey:kRTCMediaConstraintsOfferToReceiveVideo];

    NSMutableDictionary *optionesConstraints = [NSMutableDictionary dictionary];
//    if (_isRestartConnection) {
//        [optionesConstraints setObject:kRTCMediaConstraintsValueTrue forKey:kRTCMediaConstraintsIceRestart];
//    }else{
//
//    }
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc]initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:optionesConstraints];
    return constraints;
}
-(void)audioSessionConfig{
    //    if (_isClose) {
    //        return;
    //    }
    //    if (_isUserConfig) {
    //        return;
    //    }
    //    self.isUserConfig = YES;
    RTCAudioSessionConfiguration *configuration =
    [RTCAudioSessionConfiguration currentConfiguration];
    configuration.category = AVAudioSessionCategoryPlayAndRecord;
    configuration.categoryOptions = AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionMixWithOthers ;
    configuration.mode = AVAudioSessionModeVoiceChat;
    
    if (!_audioSession) {
        _audioSession = [RTCAudioSession sharedInstance];
        [_audioSession addDelegate:self];
    }
    [_audioSession lockForConfiguration];
    BOOL hasSucceeded = NO;
    NSError *error = nil;
    if (_audioSession.isActive) {
        hasSucceeded = [_audioSession setConfiguration:configuration error:&error];
    } else {
        hasSucceeded = [_audioSession setConfiguration:configuration
                                                active:YES
                                                 error:&error];
    }
    if (!hasSucceeded) {
        
        NSLog(@"Error setting configuration: %@", error.localizedDescription);
    }
    if (error) {
        
    }
    
    _audioSession.useManualAudio = YES;//开启音频控制
    _audioSession.isAudioEnabled = YES;
    [_audioSession unlockForConfiguration];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self switchAudioDeviceWithDeviceType:RTCAudioSessionDeviceTypeSpeaker];
    });
}
-(NSString *)switchAudioDeviceWithDeviceType:(RTCAudioSessionDeviceType)deviceType{
    NSMutableString *str = [NSMutableString string];
    if (deviceType == RTCAudioSessionDeviceTypeHeadsetMic ) {//耳机/蓝牙不处理切换事件
        
        return @"耳机不处理切换事件";
    }
    switch (deviceType) {
        case RTCAudioSessionDeviceTypeEarphone:{
            [self switchEarphone:YES];
        }
            
            break;
            
        case RTCAudioSessionDeviceTypeSpeaker: {
            [self switchSpeaker:YES];
            break;
        }
        case RTCAudioSessionDeviceTypeBluetooth: {
            [self switchBluetooth:YES];
            break;
        }
        case RTCAudioSessionDeviceTypeHeadsetMic: {
            
            break;
        }
    }
    return str;
}
- (BOOL)switchSpeaker:(BOOL)onOrOff
{
    NSError* audioError = nil;
    BOOL changeResult = NO;
    if (onOrOff == YES)
    {
        NSLog(@"hosten current switchSpeaker 外音");
        
        changeResult = [[RTCAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&audioError];
        [_audioSession unlockForConfiguration];
        
    }
    else
    {
        NSLog(@"hosten current switchSpeaker 听筒");
        
        [_audioSession lockForConfiguration];
        AVAudioSessionPortDescription* builtinPort = [self builtinAudioDevice];
        changeResult = [[RTCAudioSession sharedInstance] setPreferredInput:builtinPort error:&audioError];
        //        changeResult = [[RTCAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&audioError];
        [_audioSession unlockForConfiguration];
        
    }
    return changeResult;
}

/* Switching to earpiece*/
- (BOOL)switchEarphone:(BOOL)onOrOff
{
    return [self switchSpeaker:!onOrOff];
}

- (BOOL)switchBluetooth:(BOOL)onOrOff{
    NSError* audioError = nil;
    BOOL changeResult = NO;
    if (onOrOff == YES)
    {
        
        [_audioSession lockForConfiguration];
        AVAudioSessionPortDescription* _bluetoothPort = [self bluetoothAudioDevice];
        changeResult = [[RTCAudioSession sharedInstance] setPreferredInput:_bluetoothPort
                                                                     error:&audioError];
        [_audioSession unlockForConfiguration];
    }
    else
    {
        [_audioSession lockForConfiguration];
        AVAudioSessionPortDescription* builtinPort = [self builtinAudioDevice];
        changeResult = [[RTCAudioSession sharedInstance] setPreferredInput:builtinPort
                                                                     error:&audioError];
        [_audioSession unlockForConfiguration];
    }
    return changeResult;
}

- (void)unConfigureAudioSession {
    RTCAudioSessionConfiguration *configuration =
    [RTCAudioSessionConfiguration currentConfiguration];
    BOOL hasSucceeded = NO;
    NSError *error = nil;
    [_audioSession lockForConfiguration];
    hasSucceeded = [_audioSession setConfiguration:configuration active:NO error:&error];
    if (!hasSucceeded) {
        NSLog(@"Error setting configuration: %@", error.localizedDescription);
    }
    _audioSession.useManualAudio = YES;//开启音频控制
    _audioSession.isAudioEnabled = NO;
    [_audioSession unlockForConfiguration];
}
- (AVAudioSessionPortDescription*)bluetoothAudioDevice
{
    NSArray* bluetoothRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    return [self audioDeviceFromTypes:bluetoothRoutes];
}

- (AVAudioSessionPortDescription*)builtinAudioDevice
{
    NSArray* builtinRoutes = @[AVAudioSessionPortBuiltInReceiver,AVAudioSessionPortBuiltInMic];
    return [self audioDeviceFromTypes:builtinRoutes];
}

- (AVAudioSessionPortDescription*)speakerAudioDevice
{
    NSArray* builtinRoutes = @[AVAudioSessionPortBuiltInSpeaker];
    return [self audioDeviceFromTypes:builtinRoutes];
}

- (AVAudioSessionPortDescription*)audioDeviceFromTypes:(NSArray*)types
{
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if ([types containsObject:route.portType])
        {
            return route;
        }
    }
    return nil;
}
- (void)close{
    _localAudioTrack.isEnabled = false;
    _localVideoTrack.isEnabled = false;
    [_peerconnetion close];
    self.peerconnetion = nil;
    self.peerconnetionFact = nil;
    [self.sendDC close];
    self.sendDC = nil;
    self.isOffer = YES;
    [self.cacheCandidateMsg removeAllObjects];
    self.isSetRemote = NO;
   
    [self unConfigureAudioSession];
    
    
    
}
-(void)peerConnection:(RTCPeerConnection *)peerConnection didChangeConnectionState:(RTCPeerConnectionState)newState{
    //    switch (newState) {
    //        case RTCPeerConnectionStateNew:{
    //
    //        }
    //
    //            break;
    //
    //        case RTCPeerConnectionStateConnecting: {
    //
    //            break;
    //        }
    //        case RTCPeerConnectionStateConnected: {
    //
    //            break;
    //        }
    //        case RTCPeerConnectionStateDisconnected: {
    //
    //            break;
    //        }
    //        case RTCPeerConnectionStateFailed: {
    //
    //            break;
    //        }
    //        case RTCPeerConnectionStateClosed: {
    //
    //            break;
    //        }
    //    }
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate{
    if (_delegate && [_delegate respondsToSelector:@selector(peerConnectionManager:didGenerateIceCandidate:sdpMLineIndex:sdpMid:)]) {
        [_delegate peerConnectionManager:self didGenerateIceCandidate:candidate.sdp sdpMLineIndex:candidate.sdpMLineIndex sdpMid:candidate.sdpMid];
    }
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
        [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
            if (stream.videoTracks > 0) {
                RTCVideoTrack *track = stream.videoTracks[0];
                self.remoteVideoTrack = track;
                if (self.remoteVideoView) {
                    [track addRenderer:self.remoteVideoView];
                }
    
            }
        }];
//    NSArray<RTCRtpReceiver*> *receivers =  self.peerconnetion.receivers;
//    RTCMediaStreamTrack *track;
//    for (RTCRtpReceiver *rtpRtcRec in receivers) {
//        if ([rtpRtcRec.track.kind isEqualToString:@"video"]) {
//            track = rtpRtcRec.track;
//            break;
//        }
//        //                    rtpRtcRec.track.isEnabled = YES;
//    }
//    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
//        [(RTCVideoTrack*)track addRenderer:self.remoteVideoView];
//    }];
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    switch (newState) {
        case RTCIceConnectionStateNew:{
            
        }
            
            break;
            
            
        case RTCIceConnectionStateChecking: {
            
            break;
        }
        case RTCIceConnectionStateConnected: {
            // 媒体要开始通话的时候 设置音频
            [self audioSessionConfig];
            break;
        }
        case RTCIceConnectionStateCompleted: {
            
            break;
        }
        case RTCIceConnectionStateFailed: {
            
            break;
        }
        case RTCIceConnectionStateDisconnected: {
            
            break;
        }
        case RTCIceConnectionStateClosed: {
            
            break;
        }
        case RTCIceConnectionStateCount: {
            
            break;
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(peerConnectionManager:didChangeIceState:)]) {
        [_delegate peerConnectionManager:self didChangeIceState:(RTCManagerIceConnectionState)newState];
    }
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didOpenDataChannel:(nonnull RTCDataChannel *)dataChannel {
    NSLog(@"peerConnection:didOpenDataChannel 远端数据通道打开了");
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    
}


- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    
}


- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    
}


- (void)dataChannel:(nonnull RTCDataChannel *)dataChannel didReceiveMessageWithBuffer:(nonnull RTCDataBuffer *)buffer {
    NSLog(@"收到数据啦 %@",buffer.isBinary?buffer.data:[[NSString alloc]initWithData:buffer.data encoding:NSUTF8StringEncoding]);
}

- (void)dataChannelDidChangeState:(nonnull RTCDataChannel *)dataChannel {
    if (dataChannel.readyState == RTCDataChannelStateOpen) {
        NSLog(@"数据通道变化了 %@",@(dataChannel.readyState));
        
    }
}



- (void)videoView:(nonnull id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size {
    if (_remoteVideoView) {
        [self updateVideoViewFrameWithchangeVideoView:_remoteVideoView changeToSize:size];
    }else{
        self.remoteVideoSize = size;
    }
}


- (void)videoView:(nonnull RTCEAGLVideoView *)videoView didOutputVideoFrame:(nonnull RTCVideoFrame *)videoFrame {
}
- (void)updateVideoViewFrameWithchangeVideoView:(UIView*)videoView changeToSize:(CGSize) videoViewSize {
    CGRect remoteViewBounds = videoView.superview.bounds;
    if (remoteViewBounds.size.width == 0 || remoteViewBounds.size.height == 0 ){
        //        LogUtils.debug(" remoteViewBounds is error \(remoteViewBounds?.debugDescription)")
        return;
    }
    NSInteger height = 0;
    NSInteger width  = 0;
    if (remoteViewBounds.size.width > remoteViewBounds.size.height) {
        if (videoViewSize.width > videoViewSize.height) {
            height = remoteViewBounds.size.height;
            width = (height * videoViewSize.width) / (videoViewSize.height);
            if (width > remoteViewBounds.size.width) {
                int subWid = width - remoteViewBounds.size.width;
                width -= subWid;
                height = (width * videoViewSize.height) / (videoViewSize.width);
            }else{
            }
        }else{
            width = remoteViewBounds.size.width;
            height = (width * videoViewSize.height) / (videoViewSize.width);
            if (height > remoteViewBounds.size.height) {
                int subWid = height - remoteViewBounds.size.height;
                height -= subWid;
                width =  (height * videoViewSize.width) / (videoViewSize.height);
            }else{
            }
        }

      
    }else{
        if (videoViewSize.width > videoViewSize.height) {
            width = remoteViewBounds.size.width;
            height = (width * videoViewSize.height) / (videoViewSize.width);
            if (height > remoteViewBounds.size.height) {
                int subWid = height - remoteViewBounds.size.height;
                height -= subWid;
                width =  (height * videoViewSize.width) / (videoViewSize.height);
            }else{
            }
        }else{
            height = remoteViewBounds.size.height;
            width = (height * videoViewSize.width) / (videoViewSize.height);
            if (width > remoteViewBounds.size.width) {
                int subWid = width - remoteViewBounds.size.width;
                width -= subWid;
                height = (width * videoViewSize.height) / (videoViewSize.width);
            }else{
            }
        }
    }
    CGFloat x = (remoteViewBounds.size.width - width) / 2.0;
    CGFloat y = (remoteViewBounds.size.height - height)/2.0;
    videoView.frame = CGRectMake(x, y, width, height);
    videoView.backgroundColor = [UIColor blackColor];
}
-(void)dealloc{
    RTCCleanupSSL();
}
@end
