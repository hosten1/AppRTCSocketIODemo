//
//  ViewController.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "ViewController.h"
#import "LYMSocketManager.h"
#import <WebRTC/WebRTC.h>

#import "RTCLYMCameraVideoCapturer.h"


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
//打
@interface ViewController ()<RTCPeerConnectionDelegate,RTCAudioSessionDelegate,RTCDataChannelDelegate>

@property(nonatomic, strong) LYMSocketManager *socketManager;
// 是不是主叫
@property(nonatomic, strong)RTCPeerConnection *peerconnetion;
@property(nonatomic, strong)RTCPeerConnectionFactory *peerconnetionFact;

@property(nonatomic, strong)RTCDataChannel *sendDC ;
@property(nonatomic, strong)RTCAudioTrack *localAudioTrack;
@property(nonatomic, strong)RTCVideoTrack *localVideoTrack;

@property(nonatomic, assign) BOOL isOffer ;
@property(nonatomic, copy) NSDictionary *recvSdp;
@property(nonatomic, strong)NSMutableArray* cacheCandidateMsg;
@property(nonatomic, copy) NSString* selfid;
@property(nonatomic, assign) BOOL isSetRemote;

@property(nonatomic, strong) RTCLYMCameraVideoCapturer *videoCapture;
@property (strong,nonatomic)   RTCAudioSession *audioSession;
@property(nonatomic, strong) RTCCameraPreviewView *localeVideoView;
@property(nonatomic, strong) RTCEAGLVideoView *remoteVideoView;
@end

@implementation ViewController

-(RTCPeerConnectionFactory *)peerconnetionFact{
    if (!_peerconnetionFact) {
        RTCInitializeSSL();
        NSDictionary *fieldTrials = @{};
        RTCInitFieldTrialDictionary(fieldTrials);
        RTCDefaultVideoDecoderFactory *decodeFact = [[RTCDefaultVideoDecoderFactory alloc]init];
        RTCDefaultVideoEncoderFactory *encodeFact = [[RTCDefaultVideoEncoderFactory alloc]init];
//        encodeFact.preferredCodec = [[RTCVideoCodecInfo alloc]initWithName:kRTCVideoCodecH264Name];
        _peerconnetionFact = [[RTCPeerConnectionFactory alloc]initWithEncoderFactory:encodeFact decoderFactory:decodeFact];
    }
    return _peerconnetionFact;
}

-(void)dealloc{
    RTCCleanupSSL();
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_socketManager) {
        self.socketManager = [[LYMSocketManager alloc]init];
    }
    if (!_cacheCandidateMsg) {
        self.cacheCandidateMsg = [NSMutableArray array];
    }
    if (!_remoteVideoView) {
        RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc]init];
        remoteView.backgroundColor = [UIColor blackColor];
        remoteView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width*(9/16));
        self.remoteVideoView = remoteView;

    }
    if (!_localeVideoView) {
        self.localeVideoView = [[RTCCameraPreviewView alloc]init];
        _localeVideoView.frame = CGRectMake(0, 0, 100,200);
        _localeVideoView.hidden = NO;
    }
    NSString *urlString = @"https://www.lymggylove.top:443";
//    NSString *urlString = @"https://10.221.120.233:8443";
    [self.socketManager connectionSocketWithServerUrl:urlString isHttps:YES params:@{}];
    WEAKSELF
    [_socketManager listenWithCB:^(NSString * _Nonnull emit, id  _Nonnull data, emitResp  _Nonnull resp) {
        STRONGSELF
        [strongSelf _parseMdiasoupNotifyMsg:data emit:emit emitResp:resp];
    }];
    // Do any additional setup after loading the view.
}

- (void)_parseMdiasoupNotifyMsg:(id)data emit:(NSString*)emit emitResp:(emitResp  _Nonnull) resp{
    if ([emit isEqualToString:@""]) {
        
    }else if ([emit isEqualToString:@"connect"]){
        NSLog(@"===========>socket connect ");
        [self.socketManager joinwihtRoomId:@"123456" name:@"44333"];
    }else if ([emit isEqualToString:@"disconnect"]){
        
    }else if ([emit isEqualToString:@"error"]){
        
    }else if ([emit isEqualToString:@"joined"]){
        
    }else if ([emit isEqualToString:@"otherJoined"]){
        // 初始化为webrtc 相关 这里只要对方一加入就 启动webrtc
        self.isOffer = true;
        [self startRTC];
        
    }else if ([emit isEqualToString:@"leaved"]){
        
    }else if ([emit isEqualToString:@"message"]){
        int type = [data[@"type"] intValue];
               switch (type) {
                   case 0: {// offer
                       self.isOffer = false;
                       self.recvSdp = data[@"sdp"];
                      [self startRTC];
                   }
                       break;
                   case 1: {// answer
//                       console.log('offer setRemoteDescription' + JSON.stringify(data.sdp));
                       RTCSessionDescription *anserSession = [[RTCSessionDescription alloc]initWithType:RTCSdpTypeAnswer sdp:data[@"sdp"][@"sdp"]];
                       [_peerconnetion setRemoteDescription:anserSession completionHandler:^(NSError * _Nullable error) {
                                                  NSLog(@"============> setremote %@",error.localizedDescription);
                       }];
                       self.isSetRemote = YES;
                       [self addcandidateFUN];
                   }
                       break;
                   case 2: {// candidate
                       if (_isSetRemote == true) {
                           [self addcandidateFUN];
                           NSDictionary *candidateDic = data[@"candidate"];
                           if ([candidateDic isKindOfClass:[NSNull class]] ||  candidateDic.count < 1) {
                               return;
                           }
                           RTCIceCandidate *candidate = [[RTCIceCandidate alloc]initWithSdp:candidateDic[@"candidate"] sdpMLineIndex:[candidateDic[@"sdpMLineIndex"] intValue] sdpMid:candidateDic[@"sdpMid"]];
                           [self.peerconnetion addIceCandidate:candidate];
                           
                       } else {
                           [self.cacheCandidateMsg addObject:data[@"candidate"]];
                       }
                   }
                       break;

                   default:
                       break;
               }
    }
}
- (void) addcandidateFUN {
    for (NSDictionary *candidateDic in _cacheCandidateMsg) {
        RTCIceCandidate *candidate = [[RTCIceCandidate alloc]initWithSdp:candidateDic[@"candidate"] sdpMLineIndex:[candidateDic[@"sdpMLineIndex"] intValue] sdpMid:candidateDic[@"sdpMid"]];
        [self.peerconnetion addIceCandidate:candidate];
    }
   
    [self.cacheCandidateMsg removeAllObjects];
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

- (void)startRTC{
    RTCConfiguration *config = [[RTCConfiguration alloc]init];
    RTCIceServer *iceserver = [[RTCIceServer alloc]initWithURLStrings:@[@"turn:www.lymggylove.top:3478"] username:@"lym" credential:@"123456"];
    config.iceServers = @[iceserver];
    config.bundlePolicy = RTCBundlePolicyMaxBundle;
    config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
    config.iceTransportPolicy = RTCIceTransportPolicyAll;
//    config.sdpSemantics = RTCSdpSemanticsPlanB;
    config.tcpCandidatePolicy = RTCTcpCandidatePolicyDisabled;
    config.continualGatheringPolicy = RTCContinualGatheringPolicyGatherContinually;
    config.disableIPV6 = NO;
    //  这个参数必须设置
    config.logFilePath  = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] mutableCopy] stringByAppendingString:@"/log/"];
    RTCMediaConstraints *constraints =  [self _defaultPeerConnectionConstraints];
    if (!self.peerconnetionFact) {
        return;
    }
    NSAssert(self.peerconnetionFact, @"peerConnectionFactory is null ");
    self.peerconnetion  = [self.peerconnetionFact peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    NSAssert(_peerconnetion, @"peerConnection is null");
     RTCDataChannelConfiguration *configDC = [[RTCDataChannelConfiguration alloc]init];
    configDC.channelId = 0;
    configDC.isNegotiated = true;
    self.sendDC = [_peerconnetion dataChannelForLabel:@"my channal" configuration:configDC];
    NSAssert(_sendDC, @"RTCDatachannal is null");
    _sendDC.delegate = self;
    self.localVideoTrack = [self videoTrack];
    // WebRTC中封装的摄像头采集
    RTCCameraVideoCapturer *cameraCapture = [[RTCCameraVideoCapturer alloc]initWithDelegate:_localVideoTrack.source];
    // 自定义的 摄像头管理类
    self.videoCapture = [[RTCLYMCameraVideoCapturer alloc]initWithCapturer:cameraCapture];
    [self.peerconnetion addTrack:_localVideoTrack streamIds:@[kARDMediaStreamId]];
    _localVideoTrack.isEnabled = true;
    self.localAudioTrack = [self audioTrack];
    [self.peerconnetion addTrack:_localAudioTrack streamIds:@[kARDMediaStreamId]];
    if (_isOffer) {
        RTCMediaConstraints *constraints = [self _defaultOfferConstraintsIsRestartICE:NO numSimulcastLayers:1];
        WEAKSELF
        [self.peerconnetion offerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            if (!error) {
                STRONGSELF
                // 发送出去
                NSDictionary *msg = @{ @"type": @(0),
                                    @"sdp": @{@"type":@"offer",@"sdp":sdp.sdp}};
                [strongSelf.socketManager sendMessage:msg withMethod:@"message"];
                [strongSelf.peerconnetion setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"");
                    }
                }];

            }else{
                NSLog(@"");
            }
        }];
        [self.videoCapture startCaptureWithFPS:30 width:1280 height:720 completionHandler:^(NSError * _Nullable error) {
            STRONGSELF
            dispatch_main_async_safe(^{
                
                strongSelf.localeVideoView.captureSession = cameraCapture.captureSession;
                [strongSelf.view addSubview:strongSelf.localeVideoView];
            });
            
        }];
    }else{
        RTCSessionDescription *offerDesc = [[RTCSessionDescription alloc]initWithType:RTCSdpTypeOffer sdp:_recvSdp[@"sdp"]];
        WEAKSELF
        [self.peerconnetion setRemoteDescription:offerDesc completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                STRONGSELF
                strongSelf.isSetRemote = YES;
                RTCMediaConstraints *constraints = [strongSelf _defaultOfferConstraintsIsRestartICE:NO numSimulcastLayers:1];
                [strongSelf.peerconnetion answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                    if (!error) {
                        // 发送出去
                        NSDictionary *msg = @{ @"type": @(1),
                                            @"sdp": @{@"type":@"answer",@"sdp":sdp.sdp}};
                        [weakSelf.socketManager sendMessage:msg withMethod:@"message"];
                        [weakSelf.peerconnetion setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"");
                            }
                        }];
                    }else{
                        NSLog(@"");
                    }
                }];
            }else{
                NSLog(@"");
            }
        }];
    }
    
}
- (RTCMediaConstraints*)_defaultOfferConstraintsIsRestartICE:(BOOL)isRestartICE numSimulcastLayers:(NSInteger)numSimulcastLayers{
    NSMutableDictionary<NSString*,NSString*> *mandatoryConstraints = [NSMutableDictionary dictionary];
    RTCMediaConstraints *offerConstraints = nil;
    NSString *numSimulcastLayersS = numSimulcastLayers > 0 ? [NSString stringWithFormat:@"%@",@(numSimulcastLayers)] : @"1";
    if (isRestartICE) {
        mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveAudio] = kRTCMediaConstraintsValueTrue;
        mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveVideo] = kRTCMediaConstraintsValueTrue;
        //        mandatoryConstraints[kRTCMediaConstraintsIceRestart] = kRTCMediaConstraintsValueTrue;
        offerConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:@{kRTCMediaConstraintsIceRestart:kRTCMediaConstraintsValueTrue,@"googNumSimulcastLayers":numSimulcastLayersS}];
    }else{
        mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveAudio] = kRTCMediaConstraintsValueTrue;
        mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveVideo] = kRTCMediaConstraintsValueTrue;
        offerConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:@{@"googNumSimulcastLayers":numSimulcastLayersS}];
        
    }
    
    
    return offerConstraints;
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
    self.recvSdp = nil;
    self.isSetRemote = NO;
    [self.socketManager close];
    self.socketManager = nil;
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
    NSDictionary *msg = @{
        @"type": @(2),
        @"candidate":@{
            @"sdp":candidate.sdp,
            @"sdpMid":candidate.sdpMid,
            @"sdpMLineIndex":@(candidate.sdpMLineIndex)
        }
    };
//    NSLog(@"===========>socket didGenerateIceCandidate %@ ",msg.description);
    [self.socketManager sendMessage:msg withMethod:@"message"];
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    if (stream.videoTracks > 0) {
        dispatch_main_async_safe(^{
            [self.view insertSubview:self.remoteVideoView atIndex:0];
            RTCVideoTrack *track = stream.videoTracks[0];
            [track addRenderer:self.remoteVideoView];
        });
       
    }
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



@end
