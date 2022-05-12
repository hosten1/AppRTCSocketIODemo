//
//  ViewController.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "ViewController.h"
#import "LYMSocketManager.h"

#import "RTCLYMCameraVideoCapturer.h"

#import "RTCPeerConnectionManager.h"


#define KRTCSIGNALSERVER  @"www.lymggylove.top:443"
//打
@interface ViewController ()<RTCPeerConnectionManagerDelegate>

@property(nonatomic, strong) LYMSocketManager *socketManager;
@property(nonatomic, strong) RTCPeerConnectionManager *peerManager;
@property(nonatomic, strong) RTCLYMCameraVideoCapturer *videoCapture;
@property (weak, nonatomic) IBOutlet UITextField *turnTF;

@property(nonatomic, strong) UIView *localeVideoView;
@property(nonatomic, strong) UIView *remoteVideoView;
@property(nonatomic, weak) IBOutlet UIButton *startBtn;
@property(nonatomic, weak) IBOutlet UIButton *mutedBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCamera;
@property (weak, nonatomic) IBOutlet UIButton *connectServer;

@property(nonatomic, assign) BOOL isOffer;

@property(nonatomic, copy) NSString *roomId;
@end

@implementation ViewController
- (IBAction)connectServer:(UIButton *)sender {
    sender.enabled = NO;
    
    NSString *urlString = _turnTF.text.length > 5?_turnTF.text : KRTCSIGNALSERVER;
    //    NSString *urlString = @"https://10.221.120.233:8443";
    [self.socketManager connectionSocketWithServerUrl:[NSString stringWithFormat:@"https://%@",urlString] isHttps:YES params:@{}];
}
- (IBAction)endEditing:(UITextField *)sender {
    
    
}
- (IBAction)startRTCConnectoin:(UIButton *)sender {
   
    if (sender.selected) {
        [self.socketManager sendMessageWithInfo:_roomId message:@{} withMethod:@"leave"];
        [self close];
        _startBtn.titleLabel.text = @"开始";
        sender.selected = false;
    }else{
        self.roomId = @"123456";
    
        [self.socketManager joinwihtRoomId:_roomId name:@"44333"];
        _startBtn.titleLabel.text = @"";
        sender.selected = true;
       
    }
  
}
- (IBAction)switchCamera:(UIButton *)sender {
    sender.enabled = false;
    if (_videoCapture) {
        [_videoCapture switchCameraWitCcompletionHandler:^(NSError * _Nullable error) {
                    
        }];
    }
    sender.selected = !sender.selected;
}
- (IBAction)mutedBtn:(UIButton *)sender {

    
}




- (void)viewDidLoad {
    [super viewDidLoad];
    self.startBtn.enabled = NO;
    self.turnTF.text = KRTCSIGNALSERVER;
    [_startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [_startBtn setTitle:@"结束" forState:UIControlStateSelected];
    [_switchCamera setTitle:@"前置" forState:UIControlStateNormal];
    [_switchCamera setTitle:@"后置" forState:UIControlStateSelected];
    self.mutedBtn.enabled = NO;
    self.switchCamera.enabled = NO;
    if (!_socketManager) {
        self.socketManager = [[LYMSocketManager alloc]init];
        WEAKSELF
        [_socketManager listenWithCB:^(NSString * _Nonnull emit, id  _Nonnull data, emitResp  _Nonnull resp) {
            STRONGSELF
            [strongSelf _parseMdiasoupNotifyMsg:data emit:emit emitResp:resp];
        }];
    }
    if (!_peerManager) {
        self.peerManager = [[RTCPeerConnectionManager alloc]initWithUserDataChannal:true];
        _peerManager.delegate = self;
    }
   
    if (!_localeVideoView) {
        self.localeVideoView = [[UIView alloc]init];
        _localeVideoView.frame = CGRectMake(20, 20,80,120);
        _remoteVideoView.backgroundColor = [UIColor clearColor];
        _localeVideoView.hidden = YES;
        [self.view addSubview:_localeVideoView];
        
    }
    if (!_remoteVideoView) {
        self.remoteVideoView = [[UIView alloc]init];
        _remoteVideoView.backgroundColor = [UIColor clearColor];
        _remoteVideoView.frame = CGRectMake(CGRectGetMaxX(_localeVideoView.frame)+10 ,20, CGRectGetWidth(self.view.frame) - 120, 200);
        _remoteVideoView.hidden = YES;
        [self.view insertSubview:_remoteVideoView atIndex:0];
        
    }
    
}

- (void)_parseMdiasoupNotifyMsg:(id)data emit:(NSString*)emit emitResp:(emitResp  _Nonnull) resp{
    if ([emit isEqualToString:@""]) {
        
    }else if ([emit isEqualToString:@"connect"]){
        NSLog(@"===========>socket connect ");
        self.startBtn.enabled = true;
        self.localeVideoView.hidden = NO;
        self.remoteVideoView.hidden = NO;
    }else if ([emit isEqualToString:@"disconnect"]){
        
    }else if ([emit isEqualToString:@"error"]){
        
    }else if ([emit isEqualToString:@"joined"]){
        
    }else if ([emit isEqualToString:@"otherJoined"]){
        // 初始化为webrtc 相关 这里只要对方一加入就 启动webrtc
        self.isOffer = true;
        // 自定义的 摄像头管理类
        [self _startRTCWithOfferSdp:nil];
        
    }else if ([emit isEqualToString:@"leaved"]){
        
    }else if ([emit isEqualToString:@"message"]){
        int type = [data[@"type"] intValue];
        switch (type) {
            case 0: {// offer
                self.isOffer = false;
                NSDictionary *recvSdp = data[@"sdp"];
                RTCSessionDescription *offerDesc = [[RTCSessionDescription alloc]initWithType:RTCSdpTypeOffer sdp:recvSdp[@"sdp"]];
                [self _startRTCWithOfferSdp:offerDesc];
            }
                break;
            case 1: {// answer
                //                       console.log('offer setRemoteDescription' + JSON.stringify(data.sdp));
              
                [_peerManager setRemoteSDPWithSDP:data[@"sdp"][@"sdp"]];
               
            }
                break;
            case 2: {// candidate
                NSDictionary *candidateDic = data[@"candidate"];
                if ([candidateDic isKindOfClass:[NSNull class]] ||  candidateDic.count < 1) {
                    return;
                }
                [_peerManager addRemoteIceCandidateWithCandidate:candidateDic[@"candidate"]  sdpMLineIndex:[candidateDic[@"sdpMLineIndex"] intValue] sdpMid:candidateDic[@"sdpMid"]];
               
            }
                break;
                
            default:
                break;
        }
    }
}
- (void)close{
    //停止本地摄像头
    WEAKSELF
    [_videoCapture stopCaptureWitCcompletionHandler:^{
            STRONGSELF
        strongSelf.videoCapture = nil;
    }];
    self.localeVideoView.hidden = YES;
    self.remoteVideoView.hidden = YES;
    //释放其他资源
    [_peerManager close];
    // 最后关闭socket
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.socketManager close];
//        self.socketManager = nil;
        self.connectServer.enabled = YES;
    });
    self.startBtn.enabled = NO;
    self.mutedBtn.enabled = NO;
    self.switchCamera.enabled = NO;
}
- (void)_startRTCWithOfferSdp:(nullable RTCSessionDescription*)offerDesc{
    WEAKSELF
    [self.peerManager startRTCWithIsOffer:_isOffer offerSdp:offerDesc Handler:^(RTCSessionDescription * _Nullable sessionDesc, RTCCameraVideoCapturer * _Nonnull cameraCapture, NSError * _Nonnull error) {
                STRONGSELF
        if (sessionDesc) {
            NSString *sdpType = nil;
            NSNumber *msgType = nil;
            if (sessionDesc.type == RTCSdpTypeOffer) {
                sdpType =  @"offer";
                msgType = @(0);
            }else{
                sdpType =  @"answer";
                msgType = @(1);
            }
            NSDictionary *msg = @{ @"type":msgType,
                                   @"sdp": @{@"type":sdpType,@"sdp":sessionDesc.sdp}};
            [strongSelf.socketManager sendMessageWithInfo:strongSelf.roomId message:msg withMethod:@"message"];
        }
        if (cameraCapture && !strongSelf.videoCapture) {
            strongSelf.videoCapture = [[RTCLYMCameraVideoCapturer alloc]initWithCapturer:cameraCapture];
            [strongSelf.videoCapture startCaptureWithFPS:30 width:1280 height:720 completionHandler:^(NSError * _Nullable error) {
                
            }];
        }
       
        
    }];
 
}

- (void)peerConnectionManager:(nonnull RTCPeerConnectionManager *)client didChangeIceState:(RTCManagerIceConnectionState)state {
    switch (state) {
        case RTCManagerIceConnectionStateNew:{
            
        }
        break;
        case RTCManagerIceConnectionStateChecking: {
            
            break;
        }
        case RTCManagerIceConnectionStateConnected: {
            dispatch_main_async_safe(^{
                [self.peerManager addLocalView:self.localeVideoView];
                [self.peerManager addRemoteView:self.remoteVideoView userID:nil];
                self.switchCamera.enabled = YES;
            });
            break;
        }
        case RTCManagerIceConnectionStateCompleted: {
            
            break;
        }
        case RTCManagerIceConnectionStateFailed: {
            
            break;
        }
        case RTCManagerIceConnectionStateDisconnected: {
            
            break;
        }
        case RTCManagerIceConnectionStateClosed: {
            
            break;
        }
        case RTCManagerIceConnectionStateCount: {
            
            break;
        }
    }
}

- (void)peerConnectionManager:(nonnull RTCPeerConnectionManager *)client didGenerateIceCandidate:(nonnull NSString *)candidateStr sdpMLineIndex:(int)sdpMLineIndex sdpMid:(nonnull NSString *)sdpMid {
    NSDictionary *msg = @{
        @"type": @(2),
        @"candidate":@{
            @"candidate":candidateStr,
            @"sdpMid":sdpMid,
            @"sdpMLineIndex":@(sdpMLineIndex)
        }
    };
    //    NSLog(@"===========>socket didGenerateIceCandidate %@ ",msg.description);
    [self.socketManager sendMessageWithInfo:_roomId message:msg withMethod:@"message"];
}

@end
