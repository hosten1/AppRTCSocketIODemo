//
//  LYMVideoCallViewController.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2025/8/5.
//

#import "LYMVideoCallViewController.h"

#import "LYMSocketManager.h"
#import "RTCLYMCameraVideoCapturer.h"
#import "RTCPeerConnectionManager.h"
#import "RTCLYMTimer.h"
#import "FBYLineGraphView.h"

#define KRTCSIGNALSERVER  @"8.137.17.218:443"
// 颜色常量
#define PRIMARY_COLOR [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]
#define SECONDARY_COLOR [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:245.0/255.0 alpha:1.0]
#define TEXT_COLOR [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0]
#define LIGHT_TEXT_COLOR [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0]
#define SUCCESS_COLOR [UIColor colorWithRed:52.0/255.0 green:199.0/255.0 blue:89.0/255.0 alpha:1.0]
#define ERROR_COLOR [UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1.0]
#define INFO_BG_COLOR [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] // 半透明黑色背景


@interface LYMVideoCallViewController ()<RTCPeerConnectionManagerDelegate>

@property(nonatomic, strong) LYMSocketManager *socketManager;
@property(nonatomic, strong) RTCPeerConnectionManager *peerManager;
@property(nonatomic, strong) RTCLYMCameraVideoCapturer *videoCapture;

/// UI 组件
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *localeVideoView;
@property (nonatomic, strong) UIView *remoteVideoView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextField *turnTF;
@property (nonatomic, strong) UIButton *connectServerBtn;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *switchCameraBtn;
@property (nonatomic, strong) UIButton *mutedBtn;
@property (nonatomic, strong) UIButton *switchAudioDeviceBtn;
@property (nonatomic, strong) FBYLineGraphView *rttLineGraphView;
@property (nonatomic, strong) FBYLineGraphView *packLostLineGraphView;
// 新增：编解码信息标签
@property (nonatomic, strong) UILabel *codecInfoLabel;

@property (nonatomic, assign) BOOL isOffer;
@property (nonatomic, strong) RTCLYMTimer *timer;

@property(nonatomic, copy) NSString *targetId;
@end


@implementation LYMVideoCallViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    [self initializeComponents];
    if (_userName == nil) {
        _userName = @"nihao";
    }
}

- (void)setupUI {
    // 容器视图
    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"未连接";
    self.statusLabel.textColor = LIGHT_TEXT_COLOR;
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    
    // 远程视频视图
    self.remoteVideoView = [[UIView alloc] init];
    self.remoteVideoView.backgroundColor = SECONDARY_COLOR;
    self.remoteVideoView.layer.cornerRadius = 12;
    self.remoteVideoView.layer.masksToBounds = YES;
    
    // 本地视频视图
    self.localeVideoView = [[UIView alloc] init];
    self.localeVideoView.backgroundColor = SECONDARY_COLOR;
    self.localeVideoView.layer.cornerRadius = 8;
    self.localeVideoView.layer.borderWidth = 2;
    self.localeVideoView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.localeVideoView.layer.masksToBounds = YES;
    self.localeVideoView.hidden = YES;
    
    // TURN 服务器输入框
    self.turnTF = [[UITextField alloc] init];
    self.turnTF.placeholder = @"输入 TURN 服务器地址";
    self.turnTF.borderStyle = UITextBorderStyleRoundedRect;
    self.turnTF.font = [UIFont systemFontOfSize:14];
    self.turnTF.text = @"8.137.17.218:443";
    self.turnTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    // 连接服务器按钮
    self.connectServerBtn = [self createButtonWithTitle:@"连接服务器"];
    [self.connectServerBtn addTarget:self action:@selector(connectServer:) forControlEvents:UIControlEventTouchUpInside];
    
    // 开始按钮
    self.startBtn = [self createButtonWithTitle:@"开始通话"];
    [self.startBtn addTarget:self action:@selector(startRTCConnectoin:) forControlEvents:UIControlEventTouchUpInside];
    self.startBtn.backgroundColor = PRIMARY_COLOR;
    
    // 切换摄像头按钮
    self.switchCameraBtn = [self createIconButtonWithSystemName:@"camera.rotate"];
    [self.switchCameraBtn addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    
    // 静音按钮
    self.mutedBtn = [self createIconButtonWithSystemName:@"mic.slash"];
    [self.mutedBtn addTarget:self action:@selector(mutedBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    // 切换音频设备按钮
    self.switchAudioDeviceBtn = [self createIconButtonWithSystemName:@"speaker.wave.3"];
    [self.switchAudioDeviceBtn addTarget:self action:@selector(switchDevice:) forControlEvents:UIControlEventTouchUpInside];
    
    // 新增：编解码信息标签
    self.codecInfoLabel = [[UILabel alloc] init];
    self.codecInfoLabel.text = @"编解码: -";
    self.codecInfoLabel.textColor = [UIColor whiteColor];
    self.codecInfoLabel.backgroundColor = INFO_BG_COLOR;
    self.codecInfoLabel.font = [UIFont systemFontOfSize:12];
    self.codecInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.codecInfoLabel.layer.cornerRadius = 4;
    self.codecInfoLabel.layer.masksToBounds = YES;
    self.codecInfoLabel.hidden = YES;
    
    // 添加到容器
    NSArray *views = @[
        self.statusLabel,
        self.remoteVideoView,
        self.localeVideoView,
        self.turnTF,
        self.connectServerBtn,
        self.startBtn,
        self.switchCameraBtn,
        self.mutedBtn,
        self.switchAudioDeviceBtn,
        self.codecInfoLabel  // 添加编解码标签
    ];
    
    for (UIView *view in views) {
        [self.containerView addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    // 布局约束
    [self setupConstraints];
    
    // 初始化图表
    [self setupGraphViews];
}

- (void)setupConstraints {
    NSDictionary *views = @{
        @"status": self.statusLabel,
        @"remote": self.remoteVideoView,
        @"local": self.localeVideoView,
        @"turnTF": self.turnTF,
        @"connect": self.connectServerBtn,
        @"start": self.startBtn,
        @"camera": self.switchCameraBtn,
        @"mute": self.mutedBtn,
        @"audio": self.switchAudioDeviceBtn,
        @"codec": self.codecInfoLabel  // 添加编解码标签
    };
    
    // 垂直间距
    CGFloat padding = 16;
    CGFloat controlHeight = 44;
    
    [NSLayoutConstraint activateConstraints:@[
        // 状态标签
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:padding],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        
        // 远程视频
        [self.remoteVideoView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:padding],
        [self.remoteVideoView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.remoteVideoView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        [self.remoteVideoView.heightAnchor constraintEqualToAnchor:self.remoteVideoView.widthAnchor multiplier:0.75],
        
        // 新增：编解码信息标签（放在远程视频上方）
        [self.codecInfoLabel.bottomAnchor constraintEqualToAnchor:self.remoteVideoView.topAnchor constant:-padding/2],
        [self.codecInfoLabel.centerXAnchor constraintEqualToAnchor:self.remoteVideoView.centerXAnchor],
        [self.codecInfoLabel.widthAnchor constraintEqualToConstant:200],
        [self.codecInfoLabel.heightAnchor constraintEqualToConstant:24],
        
        // 本地视频 (右上角悬浮)
        [self.localeVideoView.topAnchor constraintEqualToAnchor:self.remoteVideoView.topAnchor constant:padding],
        [self.localeVideoView.trailingAnchor constraintEqualToAnchor:self.remoteVideoView.trailingAnchor constant:-padding],
        [self.localeVideoView.widthAnchor constraintEqualToAnchor:self.remoteVideoView.widthAnchor multiplier:0.3],
        [self.localeVideoView.heightAnchor constraintEqualToAnchor:self.localeVideoView.widthAnchor multiplier:0.75],
        
        // 服务器地址输入
        [self.turnTF.topAnchor constraintEqualToAnchor:self.remoteVideoView.bottomAnchor constant:padding*1.5],
        [self.turnTF.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.turnTF.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        [self.turnTF.heightAnchor constraintEqualToConstant:controlHeight],
        
        // 连接按钮
        [self.connectServerBtn.topAnchor constraintEqualToAnchor:self.turnTF.bottomAnchor constant:padding],
        [self.connectServerBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.connectServerBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        [self.connectServerBtn.heightAnchor constraintEqualToConstant:controlHeight],
        
        // 开始按钮
        [self.startBtn.topAnchor constraintEqualToAnchor:self.connectServerBtn.bottomAnchor constant:padding],
        [self.startBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.startBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        [self.startBtn.heightAnchor constraintEqualToConstant:controlHeight],
        
        // 控制按钮组
        [self.switchCameraBtn.topAnchor constraintEqualToAnchor:self.startBtn.bottomAnchor constant:padding*2],
        [self.switchCameraBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.switchCameraBtn.widthAnchor constraintEqualToConstant:60],
        [self.switchCameraBtn.heightAnchor constraintEqualToConstant:60],
        
        [self.mutedBtn.topAnchor constraintEqualToAnchor:self.switchCameraBtn.topAnchor],
        [self.mutedBtn.trailingAnchor constraintEqualToAnchor:self.switchCameraBtn.leadingAnchor constant:-padding*2],
        [self.mutedBtn.widthAnchor constraintEqualToConstant:60],
        [self.mutedBtn.heightAnchor constraintEqualToConstant:60],
        
        [self.switchAudioDeviceBtn.topAnchor constraintEqualToAnchor:self.switchCameraBtn.topAnchor],
        [self.switchAudioDeviceBtn.leadingAnchor constraintEqualToAnchor:self.switchCameraBtn.trailingAnchor constant:padding*2],
        [self.switchAudioDeviceBtn.widthAnchor constraintEqualToConstant:60],
        [self.switchAudioDeviceBtn.heightAnchor constraintEqualToConstant:60],
    ]];
}

- (void)setupGraphViews {
    // RTT 图表
    self.rttLineGraphView = [[FBYLineGraphView alloc] init];
    self.rttLineGraphView.title = @"RTT (ms)";
    self.rttLineGraphView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.rttLineGraphView.layer.cornerRadius = 10;
    
    // 丢包率图表
    self.packLostLineGraphView = [[FBYLineGraphView alloc] init];
    self.packLostLineGraphView.title = @"丢包率 (%)";
    self.packLostLineGraphView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.packLostLineGraphView.layer.cornerRadius = 10;
    
    [self.containerView addSubview:self.rttLineGraphView];
    [self.containerView addSubview:self.packLostLineGraphView];
    
    self.rttLineGraphView.translatesAutoresizingMaskIntoConstraints = NO;
    self.packLostLineGraphView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    int padding = 10;
    // 图表布局
    [NSLayoutConstraint activateConstraints:@[
        [self.rttLineGraphView.topAnchor constraintEqualToAnchor:self.switchCameraBtn.bottomAnchor constant:20],
        [self.rttLineGraphView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding],
        [self.rttLineGraphView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.45],
        [self.rttLineGraphView.heightAnchor constraintEqualToConstant:120],
        
        [self.packLostLineGraphView.topAnchor constraintEqualToAnchor:self.rttLineGraphView.topAnchor],
        [self.packLostLineGraphView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-padding],
        [self.packLostLineGraphView.widthAnchor constraintEqualToAnchor:self.rttLineGraphView.widthAnchor],
        [self.packLostLineGraphView.heightAnchor constraintEqualToAnchor:self.rttLineGraphView.heightAnchor],
        [self.packLostLineGraphView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
}

- (UIButton *)createButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = PRIMARY_COLOR;
    button.layer.cornerRadius = 10;
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    return button;
}

- (UIButton *)createIconButtonWithSystemName:(NSString *)systemName {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *icon = [UIImage systemImageNamed:systemName];
    [button setImage:icon forState:UIControlStateNormal];
    button.tintColor = [UIColor whiteColor];
    button.backgroundColor = PRIMARY_COLOR;
    button.layer.cornerRadius = 30;
    return button;
}

- (void)initializeComponents {
    self.socketManager = [[LYMSocketManager alloc] init];
    self.peerManager = [[RTCPeerConnectionManager alloc] initWithUserDataChannal:YES];
    self.peerManager.delegate = self;
    
    WEAKSELF
    [self.socketManager listenWithCB:^(NSString *emit, NSString *data1, NSString *data2, id data, emitResp resp) {
        STRONGSELF
        if (data) {
            [strongSelf _parseMdiasoupNotifyMsg:data emit:emit emitResp:resp];
        }
    }];
}

- (void)updateConnectionStatus:(NSString *)status color:(UIColor *)color {
    self.statusLabel.text = status;
    self.statusLabel.textColor = color;
}

#pragma mark - Button Actions

- (IBAction)connectServer:(UIButton *)sender {
    sender.enabled = NO;
    NSString *urlString = self.turnTF.text.length > 5 ? self.turnTF.text : @"8.137.17.218:443";
    [self updateConnectionStatus:@"连接中..." color:LIGHT_TEXT_COLOR];
    
    [self.socketManager connectionSocketWithServerUrl:[NSString stringWithFormat:@"https://%@", urlString]
                                             isHttps:YES
                                              params:@{}];
}

- (void)startRTCConnectoin:(UIButton *)sender {
    if (sender.selected) {
        [self.socketManager sendMessageWithInfo:self.roomId message:@{
            @"roomId":_roomId,
            @"senderId":_userId
        } withMethod:@"leave"];
        [self close];
        [sender setTitle:@"开始通话" forState:UIControlStateNormal];
        sender.selected = NO;
        [self updateConnectionStatus:@"通话已结束" color:ERROR_COLOR];
    } else {
//        self.roomId = @"123456";
        [self.socketManager joinwihtRoomId:self.roomId ownerId:_userId name:_userName callback:^(NSDictionary * _Nonnull data) {
            
        } ];
        [sender setTitle:@"结束通话" forState:UIControlStateNormal];
        sender.selected = YES;
        [self updateConnectionStatus:@"正在建立连接..." color:SUCCESS_COLOR];
    }
}

- (IBAction)switchCamera:(UIButton *)sender {
    sender.enabled = NO;
    if (self.videoCapture) {
        [self.videoCapture switchCameraWitCcompletionHandler:^(NSError *error) {
            dispatch_main_async_safe(^{
                sender.enabled = YES;
            });
        }];
    }
    sender.selected = !sender.selected;
}

- (IBAction)mutedBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
//    [self.peerManager setAudioEnabled:!sender.selected];
}

- (IBAction)switchDevice:(UIButton *)sender {
    if (!sender.selected) {
        [self.peerManager switchAudioDeviceWithDeviceType:RTCAudioSessionDeviceTypeSpeaker];
    } else {
        [self.peerManager switchAudioDeviceWithDeviceType:RTCAudioSessionDeviceTypeEarphone];
    }
    sender.selected = !sender.selected;
}

#pragma mark - 核心功能 (保持不变)


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
        NSLog(@"otherJoined: %@", data);
        NSString *senderId = data[@"senderId"];
        self.targetId = senderId;
        // 初始化为webrtc 相关 这里只要对方一加入就 启动webrtc
        self.isOffer = true;
        // 自定义的 摄像头管理类
        [self _startRTCWithOfferSdp:nil];
        
//        // 检查是否已存在该用户的peer连接
//        if (![strongSelf.peerManager hasConnectionForUser:senderId]) {
//            // 添加远端视频视图
//            [strongSelf addRemoteVideoForUser:senderId];
//
//            // 初始化Peer连接
//            [strongSelf initPeerConnectionForUser:senderId isOffer:YES];
//
//            // 更新日志
//            NSString *joinMsg = [NSString stringWithFormat:@"用户 %@ 加入了房间", senderId];
//            [strongSelf appendLogMessage:joinMsg];
//        } else {
//            NSString *errorMsg = [NSString stringWithFormat:@"用户 %@ 的连接已存在", senderId];
//            NSLog(@"%@", errorMsg);
//            [strongSelf appendLogMessage:errorMsg];
//        }
        
    }else if ([emit isEqualToString:@"leaved"]){
        
        NSLog(@"leaved: %@", data);
        NSString *senderId = data[@"senderId"];
        [self close];
        // 更新日志
        NSString *leaveMsg = [NSString stringWithFormat:@"用户 %@ 离开了房间", senderId];
        
    }else if ([emit isEqualToString:@"message"]){
        NSString *senderId = data[@"senderId"];
        if(!_targetId){
            self.targetId = senderId;
        }
//        if (id === selfid) {
//                        console.error(`lym id errr selfid:${selfid} senderId:${senderId}`);
//                        return;
//        }
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
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCapture stopCaptureWitCcompletionHandler:^{
            STRONGSELF
            strongSelf.videoCapture = nil;
            //释放其他资源
            [strongSelf.peerManager close];
        }];
    });

    self.localeVideoView.hidden = YES;
    self.remoteVideoView.hidden = YES;
    //释放其他资源
    [_peerManager close];
    // 最后关闭socket
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.socketManager close];
        //        self.socketManager = nil;
//        self.connectServer.enabled = YES;
    });
    self.startBtn.enabled = NO;
    self.mutedBtn.enabled = NO;
    [self.navigationController popViewControllerAnimated:YES];
//    self.switchCamera.enabled = NO;
//    self.switchAudioDevice.enabled = NO;
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
            NSDictionary *msg = @{@"targetId":self.targetId,
                                  @"roomId":self.roomId,
                                  @"senderId":self.userId,
                                   @"type":msgType,
                                   @"sdp": @{@"type":sdpType,@"sdp":sessionDesc.sdp}};
            [strongSelf.socketManager sendMessageWithInfo:strongSelf.roomId message:msg withMethod:@"message"];
        }
        if (cameraCapture && !strongSelf.videoCapture) {
            strongSelf.videoCapture = [[RTCLYMCameraVideoCapturer alloc]initWithCapturer:cameraCapture];
            [strongSelf.videoCapture startCaptureWithFPS:30 width:1280 height:720 completionHandler:^(NSError * _Nullable error) {
                
            }];
        }
        [strongSelf.peerManager addLocalView:strongSelf.localeVideoView];

        
        
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
                [self.peerManager addRemoteView:self.remoteVideoView userID:self.userId];
                self.switchCameraBtn.enabled = YES;
                self.mutedBtn.enabled = YES;
                self.switchAudioDeviceBtn.enabled = YES;
                [self  showStates];
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
                
                // 新增：更新编解码信息
                [strongSelf updateCodecInfoWithStats:dataCb];
            }];
        } startInterval:1 interbal:1 repeat:YES async:YES];
    }
    
    
}

// 新增：更新编解码信息显示
// 更新编解码信息显示
- (void)updateCodecInfoWithStats:(NSDictionary<NSString *,id> *)stats {
    // 视频编解码器 - 优先使用发送端信息
    NSString *videoCodec = @"-";
    if (stats[@"videoSendCodec"]) {
        videoCodec = stats[@"videoSendCodec"];
    } else if (stats[@"videoRecvCodec"]) {
        videoCodec = stats[@"videoRecvCodec"];
    }
    
    // 音频编解码器 - 根据实际使用情况判断
    NSString *audioCodec = @"-";
    if (stats[@"audioSendBitrate"] && ![stats[@"audioSendBitrate"] isEqualToString:@"0bps"]) {
        audioCodec = @"opus"; // 发送端有音频数据，默认为opus
    } else if (stats[@"audioRecvBitrate"] && ![stats[@"audioRecvBitrate"] isEqualToString:@"0bps"]) {
        audioCodec = @"opus"; // 接收端有音频数据，默认为opus
    }
    
    // 分辨率信息
    NSString *resolution = @"-";
    if (stats[@"videoSendWidth"] && stats[@"videoSendHeight"]) {
        int width = [stats[@"videoSendWidth"] intValue];
        int height = [stats[@"videoSendHeight"] intValue];
        if (width > 0 && height > 0) {
            resolution = [NSString stringWithFormat:@"%dx%d", width, height];
        }
    } else if (stats[@"videoRecvWidth"] && stats[@"videoRecvHeight"]) {
        int width = [stats[@"videoRecvWidth"] intValue];
        int height = [stats[@"videoRecvHeight"] intValue];
        if (width > 0 && height > 0) {
            resolution = [NSString stringWithFormat:@"%dx%d", width, height];
        }
    }
    
    // 创建显示字符串
    NSString *codecInfo = [NSString stringWithFormat:@"视频: %@ %@ | 音频: %@",
                           videoCodec, resolution, audioCodec];
    
    // 更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.codecInfoLabel.text = codecInfo;
        self.codecInfoLabel.hidden = NO;
        
        // 根据编解码器调整标签宽度
        CGFloat requiredWidth = [codecInfo sizeWithAttributes:@{NSFontAttributeName: self.codecInfoLabel.font}].width + 20;
        [self.codecInfoLabel.widthAnchor constraintEqualToConstant:MAX(200, requiredWidth)].active = YES;
    });
}


- (void)peerConnectionManager:(nonnull RTCPeerConnectionManager *)client didGenerateIceCandidate:(nonnull NSString *)candidateStr sdpMLineIndex:(int)sdpMLineIndex sdpMid:(nonnull NSString *)sdpMid {
    NSDictionary *msg = @{
        @"type": @(2),
        @"targetId":_targetId,
        @"roomId":_roomId,
        @"senderId":_userId,
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
