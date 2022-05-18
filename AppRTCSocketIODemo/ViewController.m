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
#import "RTCLYMTimer.h"
#import "FBYLineGraphView.h"


#define KRTCSIGNALSERVER  @"www.lymggylove.top:443"
//打
@interface ViewController ()<RTCPeerConnectionManagerDelegate>

@property(nonatomic, strong) LYMSocketManager *socketManager;
@property(nonatomic, strong) RTCPeerConnectionManager *peerManager;
@property(nonatomic, strong) RTCLYMCameraVideoCapturer *videoCapture;
@property (weak, nonatomic) IBOutlet UITextField *turnTF;

@property(nonatomic, strong) UIView *localeVideoView;
@property(nonatomic, strong) UIView *remoteVideoView;

@property(nonatomic, strong) RTCLYMTimer *timer;
/**
 getstates 信息显示
 */
@property(nonatomic,strong)FBYLineGraphView *rttLineGraphView;
@property(nonatomic,strong)FBYLineGraphView *packLostLineGraphView;
@property(nonatomic, weak) IBOutlet UIButton *startBtn;
@property(nonatomic, weak) IBOutlet UIButton *mutedBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCamera;
@property (weak, nonatomic) IBOutlet UIButton *connectServer;
@property (weak, nonatomic) IBOutlet UIButton *switchAudioDevice;

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
            dispatch_main_async_safe(^{
                sender.enabled = true;
            });
        }];
    }
    sender.selected = !sender.selected;
}
- (IBAction)mutedBtn:(UIButton *)sender {
    [self showStates];
    
}


- (IBAction)switchDevice:(UIButton *)sender {
    if (!sender.selected) {
        if (_peerManager) {
            [_peerManager switchAudioDeviceWithDeviceType:RTCAudioSessionDeviceTypeSpeaker];
        }
    }else{
        if (_peerManager) {
            [_peerManager switchAudioDeviceWithDeviceType:RTCAudioSessionDeviceTypeEarphone];
        }
    }
  
    sender.selected = !sender.selected;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.startBtn.enabled = NO;
    self.turnTF.text = KRTCSIGNALSERVER;
    [_startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [_startBtn setTitle:@"结束" forState:UIControlStateSelected];
    [_switchCamera setTitle:@"前置" forState:UIControlStateNormal];
    [_switchCamera setTitle:@"后置" forState:UIControlStateSelected];
    [_switchAudioDevice setTitle:@"听筒" forState:UIControlStateNormal];
    [_switchAudioDevice setTitle:@"外放" forState:UIControlStateSelected];
    self.mutedBtn.enabled = NO;
    self.switchCamera.enabled = NO;
    self.switchAudioDevice.enabled = NO;
    [self setupRttlineViewWithView:self.view];
    [self setupPackLostGraphView];

    if (!_socketManager) {
        self.socketManager = [[LYMSocketManager alloc]init];
        WEAKSELF
        [_socketManager listenWithCB:^(NSString * _Nonnull emit, NSString * _Nullable data1, NSString * _Nullable data2, id  _Nullable data, emitResp  _Nullable resp) {
            STRONGSELF
            if (data) {
                [strongSelf _parseMdiasoupNotifyMsg:data emit:emit emitResp:resp];
            }
           
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
    self.switchAudioDevice.enabled = NO;
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

- (void)setupRttlineViewWithView:(UIView*)supView{
    // 初始化折线图
    _rttLineGraphView = [[FBYLineGraphView alloc] initWithFrame:CGRectMake(0, self.turnTF.frame.origin.y - 210,CGRectGetWidth(self.view.frame) - 30,150)];
    // 设置折线图属性
    _rttLineGraphView.title = @"RTT往返时间"; // 折线图名称
    _rttLineGraphView.maxValue = 100;   // 最大值
    _rttLineGraphView.yMarkTitles = @[@"0",@"2",@"5",@"7",@"10",@"30",@"50",@"70"]; // Y轴刻度标签
    _rttLineGraphView.xMarkTitles = @[@"0",@"10",@"30",@"50",@"70"]; // X轴刻度标签
    _rttLineGraphView.xScaleMarkLEN = 1;
    //线一
    [_rttLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",0]]; // X轴刻度标签及相应的值
    [_rttLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",0] lineColor: [UIColor yellowColor]];
    //添加触摸手势
    //线二
    [_rttLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",1]]; // X轴刻度标签及相应的值
    [_rttLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",1] lineColor: [UIColor colorWithRed:0/255.0 green:255/255.0 blue:69/255.0 alpha:1]];
    [supView addSubview:_rttLineGraphView];
}
- (void)setupPackLostGraphView{
    // 初始化折线图
    _packLostLineGraphView = [[FBYLineGraphView alloc] initWithFrame:CGRectMake(5,CGRectGetMinY(_rttLineGraphView.frame) - 300,CGRectGetWidth(self.view.frame) - 30,300)];
    //    _sendPackLostGraphView.backgroundColor = [UIColor c];
    // 设置折线图属性
    
    _packLostLineGraphView.title = @"丢包"; // 折线图名称
    _packLostLineGraphView.maxValue = 3000;   // 最大值
    _packLostLineGraphView.yMarkTitles = @[@"0",@"500",@"800",@"1000",@"1300",@"1500",@"2000",@"2500"]; // Y轴刻度标签
    _packLostLineGraphView.xMarkTitles = @[@"0",@"10",@"30",@"50",@"80"]; // X轴刻度标签
    _packLostLineGraphView.xScaleMarkLEN = 1;
    _packLostLineGraphView.lineCont = 2;
    //线一
    [_packLostLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",0]]; // X轴刻度标签及相应的值
    [_packLostLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",0] lineColor: [UIColor yellowColor]];
    //线二
    [_packLostLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",1]]; // X轴刻度标签及相应的值
    [_packLostLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",1] lineColor: [UIColor colorWithRed:0/255.0 green:255/255.0 blue:69/255.0 alpha:1]];
    
    [self.view addSubview:_packLostLineGraphView];
}
//- (void)setupRecivePackLostLineGraphView{
//    // 初始化折线图
//    _recivePackLostLineGraphView = [[FBYLineGraphView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_sendPackLostGraphView.frame),CGRectGetWidth(_scrollView.frame)-20, 150)];
//
//    // 设置折线图属性
//
//    _recivePackLostLineGraphView.title = @"接收方丢包"; // 折线图名称
//    _recivePackLostLineGraphView.maxValue = 160;   // 最大值
//    _recivePackLostLineGraphView.yMarkTitles = @[@"0",@"10",@"30",@"50"]; // Y轴刻度标签
//    _recivePackLostLineGraphView.xMarkTitles = @[@"0",@"10",@"30",@"50"]; // X轴刻度标签
//    _recivePackLostLineGraphView.xScaleMarkLEN = 10;
//    [_recivePackLostLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",0]]; // X轴刻度标签及相应的值
//    [_recivePackLostLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",0]];
//
//    //设置完数据等属性后绘图折线图
//    [self.scrollView addSubview:_recivePackLostLineGraphView];
//}
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
                self.mutedBtn.enabled = YES;
                self.switchAudioDevice.enabled = YES;
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
- (void)showStates{
//    if (!_statesView) {
//        NSArray * _titles = @[@"呼叫前", @"通话中"];
//        _statesView = [[LDRTCStatesLogView alloc] initWithTitles:_titles isCall:NO stats:2];
//        [self.view addSubview:_statesView];
//
//        //                       initWithFrame:CGRectMake(20, _singleChatBtnsView.btnContainsViewTop - 230,SCREEN_WIDTH - 40, 200) isCall:self.isCall];
//    }
//    if (_statesView) {
////        WEAKSELF
//        [_statesView showStatesView];
////        [_statesView updateAVBeforeWithDictionary:_beforeCallState];
//        [_statesView onViewControllerClose:^(BOOL isClose) {//log信息页面关闭后音视频小窗口恢复
////            __strong typeof(weakSelf) strongSelf = weakSelf;
////            dispatch_async(dispatch_get_main_queue(), ^{
////
////            });
//
//        }];
//    }
    if (!_timer) {
        self.timer = [[RTCLYMTimer alloc]init];
        [_timer execTimerWithTask:^(NSInteger count) {
            WEAKSELF
            [self.peerManager getStatesWithCallBack:^(NSDictionary<NSString *,id> * _Nonnull dataCb) {
                STRONGSELF
                [strongSelf _statsStringWithDic:dataCb withSessionid:strongSelf.roomId];
            }];
        } startInterval:1 interbal:1 repeat:YES async:YES];
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
- (NSDictionary *)_statsStringWithDic:(NSDictionary*)dic withSessionid:(NSString*)sessionid {
   
    if (_rttLineGraphView) {
        //设置完数据等属性后绘图折线图
        [_rttLineGraphView setXMarkY:@([dic[@"connRtt"] integerValue]) lineId:[NSString stringWithFormat:@"%d",0]];
        [_rttLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",0]];
    }
    if (_packLostLineGraphView) {
        NSInteger recv = [dic[@"connRecvBitrateNum"] doubleValue]/1000 ;
        NSInteger send = [dic[@"connSendBitrateNum"] doubleValue]/1000 ;
//        NSLog(@"--------> %@,%@",@(recv) ,@(send));

        //设置完数据等属性后绘图折线图
        [_packLostLineGraphView setXMarkY:@(recv) lineId:[NSString stringWithFormat:@"%d",0]];
        [_packLostLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",0]];
        [_packLostLineGraphView setXMarkY:@(send) lineId:[NSString stringWithFormat:@"%d",1]];
        [_packLostLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",1]];
    }
//    if (!_statesView.isHiddent) {
//        [_statesView updateLogMsgWithDictionary:[[NSDictionary alloc] initWithDictionary:resultDic]];
//    }
    
    //显示详细信息
    return dic;
}
//传入 秒  得到 xx:xx:xx
-(NSString *)_getMMSSFromSS:(NSInteger)totalTime{
    
    NSInteger seconds = totalTime;
    
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",(long)seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(long)(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",(long)seconds%60];
    //format of time
    NSString *format_time = nil;
    if (![str_hour isEqualToString:@"00"]) {
        format_time =  [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    }else{
        format_time =  [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    }
    
    return format_time;
    
}
@end
