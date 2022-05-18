//
//  RTCStatesViewController.m
//  VIMRTCChatUI
//
//  Created by ymluo on 2018/7/30.
//  Copyright © 2018年 ymluo. All rights reserved.
//

#import "RTCStatesViewController.h"
#import "FBYLineGraphView.h"
#import "RTCUISegmentedView.h"

@interface RTCStatesViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic, strong) UITableView *logTableView;
@property(nonatomic, strong) UITableView *beforeLogTableView;

@property(nonatomic,copy)clsed closeCB;
@property(nonatomic,strong)FBYLineGraphView *rttLineGraphView;
@property(nonatomic,strong)FBYLineGraphView *packLostLineGraphView;
@property(nonatomic, strong) NSDictionary *logMsgDic;
@property(nonatomic, strong) NSDictionary *logBeforeDic;

@property(nonatomic, assign) NSInteger updateCounet;

/**
 *  显示折线图的可滑动视图
 */
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong)UITapGestureRecognizer *hiddenViewTapGestureRecognizer;
@property (nonatomic, strong)RTCUISegmentedView *segView;
@property (nonatomic, assign)NSInteger states;
@property (nonatomic, strong)NSArray<NSString*>* titles;


@end
#define KCellHeight 25
static NSString  * const statesLogCell = @"statesLogCell";
static NSString  * const beforeLogTableViewCell = @"beforeLogTableViewCell";

@implementation RTCStatesViewController
-(instancetype)initWithStates:(NSInteger)states titles:(NSArray<NSString *> *)titles{
   self = [super init];
    if (self) {
        self.states = states;
        self.titles = titles;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *cancleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancleButton.frame = CGRectMake(0, 0, 40, 40);
    [cancleButton setTitle:@"返回" forState:UIControlStateNormal];
    [cancleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(cancleButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithCustomView:cancleButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    if (_states == 0) {
        _segView = [[RTCUISegmentedView alloc]initWithNumberOfTitles:_titles andFrame:CGRectMake(0, 0, self.view.frame.size.width*0.6, 40) defauleSelectIndex:1];
        WEAKSELF
        [_segView onSelectIndex:^(NSInteger index) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (index == 0) {
                    [weakSelf clearDefaultView];
                    [weakSelf setUpBeforeVideoView];
                }else{
                    if (weakSelf.beforeLogTableView) {
                        [weakSelf.beforeLogTableView removeFromSuperview];
                        weakSelf.beforeLogTableView.delegate = nil;
                        weakSelf.beforeLogTableView = nil;
                    }
                    [weakSelf setUplogTableView];
                    //        [self setUpDefaultView];
                }
            });
        }];
        //将segmentedControl添加到导航条上
        self.navigationItem.titleView = _segView;
        // 默认显示OneVc的内容
        [self setUplogTableView];
    }else if(_states == 1){
        [self clearDefaultView];
        [self setUpBeforeVideoView];
    }else if(_states == 2){
        [self clearDefaultView];
        [self setUplogTableView];
    }
}
-(void)onViewControllerClose:(clsed)close{
    if (close) {
        _closeCB = close;
    }
}
-(void)updateLogMsgWithDictionary:(NSDictionary *)dicStates{
    self.logMsgDic = dicStates;
    _updateCounet ++;
    //    NSLog(@"hosten------->%@",self.logMsgDic.description);
    if (self.logTableView) {
        [self.logTableView reloadData];
    }
}
-(void)updateAVBeforeWithDictionary:(NSDictionary *)dicStates{
    if (dicStates) {
        _logBeforeDic = dicStates;
    }
}
-(void)cancleButtonClicked:(UIButton*)sender{
    _closeCB(YES);
}
//点击按钮事件
-(void)segmentValueChanged:(UISegmentedControl *)seg{
    
    NSUInteger segIndex = [seg selectedSegmentIndex];
    //    UIViewController *controller = [self controllerForSegIndex:segIndex];
    //NSArray *array2 = [self.view subviews];
    //NSLog(@"array2-->%@",array2);
    //将当旧VC的view移除，然后在添加新VC的view
    if (segIndex == 0) {
        [self clearDefaultView];
        [self setUpBeforeVideoView];
    }else{
        if (_beforeLogTableView) {
            [_beforeLogTableView removeFromSuperview];
            _beforeLogTableView.delegate = nil;
            _beforeLogTableView = nil;
        }
        [self setUplogTableView];
        //        [self setUpDefaultView];
    }
}
- (void)setUpBeforeVideoView{
    _beforeLogTableView = [[UITableView alloc]init];
    _beforeLogTableView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
    _beforeLogTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_beforeLogTableView];
    _beforeLogTableView.dataSource = self;
    _beforeLogTableView.delegate   = self;
    _beforeLogTableView.contentInset = UIEdgeInsetsZero;
    _beforeLogTableView.tag = 1001;
    _beforeLogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_beforeLogTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:beforeLogTableViewCell];
}
- (void)setUpDefaultView{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_logTableView.frame)+10, self.view.frame.size.width,self.view.frame.size.height - CGRectGetMaxY(_logTableView.frame))];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:self.scrollView];
//    [self setupRttlineView];
    //    [self setupPackLostGraphView];
//    _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width,200);
}
- (void)clearDefaultView{
    if (_logTableView) {
        [_logTableView removeFromSuperview];
        _logTableView.delegate = nil;
        _logTableView = nil;
    }
    if (_scrollView) {
        for (UIView* subView in _scrollView.subviews) {
            [subView removeFromSuperview];
        }
        [_scrollView removeFromSuperview];
        _scrollView = nil;
    }
    
}
-(void)setUplogTableView{
    _logTableView = [[UITableView alloc]init];
    _logTableView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
    _logTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_logTableView];
    _logTableView.dataSource = self;
    _logTableView.delegate   = self;
    _logTableView.tag = 1000;
    _logTableView.contentInset = UIEdgeInsetsZero;
    _logTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_logTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:statesLogCell];
}
- (void)setupRttlineViewWithView:(UIView*)supView{
    // 初始化折线图
    _rttLineGraphView = [[FBYLineGraphView alloc] initWithFrame:CGRectMake(5, 0,CGRectGetWidth(supView.frame) - 10, 200)];
    // 设置折线图属性
    _rttLineGraphView.title = @"RTT往返时间"; // 折线图名称
    _rttLineGraphView.maxValue = 60;   // 最大值
    _rttLineGraphView.yMarkTitles = @[@"0",@"15",@"30",@"45",@"60"]; // Y轴刻度标签
    _rttLineGraphView.xMarkTitles = @[@"0",@"10",@"30",@"50"]; // X轴刻度标签
    _rttLineGraphView.xScaleMarkLEN = 1;
    //线一
    [_rttLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",0]]; // X轴刻度标签及相应的值
    [_rttLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",0] lineColor: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1]];
    //添加触摸手势
//    _hiddenViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                                              action:@selector(hiddenTapGestureRecognizerSingle:)];
//    [_rttLineGraphView addGestureRecognizer:_hiddenViewTapGestureRecognizer];
    //线二
    [_rttLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",1]]; // X轴刻度标签及相应的值
    [_rttLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",1] lineColor: [UIColor colorWithRed:0/255.0 green:255/255.0 blue:69/255.0 alpha:1]];
    [supView addSubview:_rttLineGraphView];
}
- (void)hiddenTapGestureRecognizerSingle:(UITapGestureRecognizer*)tapReg{
    if (tapReg.state == UIGestureRecognizerStateEnded) {
        [self closeLineView];
    }
}
-(void)closeLineView{
    [_scrollView removeFromSuperview];
    _scrollView = nil;
    [_rttLineGraphView removeFromSuperview];
    _rttLineGraphView = nil;
    _logTableView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
    
}
- (void)setupPackLostGraphView{
    // 初始化折线图
    _packLostLineGraphView = [[FBYLineGraphView alloc] initWithFrame:CGRectMake(10,CGRectGetMaxY(_rttLineGraphView.frame),CGRectGetWidth(_scrollView.frame)-20, 150)];
    //    _sendPackLostGraphView.backgroundColor = [UIColor c];
    // 设置折线图属性
    
    _packLostLineGraphView.title = @"丢包"; // 折线图名称
    _packLostLineGraphView.maxValue = 160;   // 最大值
    _packLostLineGraphView.yMarkTitles = @[@"0",@"10",@"30",@"50"]; // Y轴刻度标签
    _packLostLineGraphView.xMarkTitles = @[@"0",@"10",@"30",@"50"]; // X轴刻度标签
    _packLostLineGraphView.xScaleMarkLEN = 10;
    //线一
    [_packLostLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",0]]; // X轴刻度标签及相应的值
    [_packLostLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",0] lineColor: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1]];
    //线二
    [_packLostLineGraphView setXMarkY:@0 lineId:[NSString stringWithFormat:@"%d",1]]; // X轴刻度标签及相应的值
    [_packLostLineGraphView mappingWithLineId:[NSString stringWithFormat:@"%d",1] lineColor: [UIColor colorWithRed:0/255.0 green:255/255.0 blue:69/255.0 alpha:1]];
    
    [self.scrollView addSubview:_packLostLineGraphView];
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
#pragma mark  ---UITableViewDelgate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView.tag == 1000) {
        if (_states == 2) {
            return 4;
        }else{
            return 6;
        }
    }else if (tableView.tag == 1001){
        return 3;
    }
    return 0;
    
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView.tag == 1000) {
        if (section == 0) {
            if (_states == 2) {
                return 2;

            }else{
                return 3;
            }
        } else if(section == 1){
            return 6;
        }else if(section == 2){
            if (_states == 2) {
                return 1;
            }else{
                return 2;
            }
        }if(section == 3){
            if (_states == 2) {
                return 1;
            }else{
                return 2;
            }
        }else{
            return 1;
        }
        
    }else if (tableView.tag == 1001){
        if (section == 0) {
            return 2;
        } else if(section == 1){
            return 2;
        }else{
            return 3;
        }
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if (tableView.tag == 1000) {
        if (_states == 2) {
            cell = [self mutChatingViewToStatsViewWithindex:indexPath tableView:tableView];
        }else{
            cell = [self chatingViewToStatsViewWithindex:indexPath tableView:tableView];

        }
    } else {
        //呼叫前页面
       cell = [self _beforeCalledStatsViewWithindex:indexPath tableView:tableView];
       
    }
    
    
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == 1000) {
        if (indexPath.section == 5) {
            return 200;
        }
        return KCellHeight;
        
    } else {
        return 40;
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // 1 松开手选中颜色消失
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // 2
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    // 3点击没有颜色改变
    cell.selected = NO;
//    if (tableView.tag == 1000) {
//
//        if (indexPath.section == 2) {
//            if (indexPath.row == 1) {
//                if (!_scrollView) {
//                    tableView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - 210);
//                    [self setUpDefaultView];
//                }else{
//                    [self closeLineView];
//                }
//            }
//        }else if (indexPath.section == 3){
//            if (indexPath.row == 1) {
//                if (!_scrollView) {
//                    tableView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - 210);
//                    [self setUpDefaultView];
//                }else{
//                    [self closeLineView];
//                }
//            }
//        }
//    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView.tag == 1000) {
        if (section == 5) {
            return CGFLOAT_MIN;
        }
        return  30;
    }else if (tableView.tag == 1001){
        return 50;
    }
    return CGFLOAT_MIN;
}
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *titlelab = [[UILabel alloc]initWithFrame:CGRectMake(6, 0, tableView.frame.size.width-10, 20)];
    titlelab.backgroundColor = [UIColor clearColor];
    titlelab.textColor = [UIColor blackColor];
    titlelab.font = [UIFont systemFontOfSize:15];
    titlelab.textColor = [UIColor whiteColor];
    if (tableView.tag == 1000) {
        if (section == 0) {//56 61 121
//            titlelab.backgroundColor = [UIColor colorWithRed:(208.0/255.0) green:(150.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  媒体"];
        } else if(section == 1){
//            titlelab.backgroundColor = [UIColor colorWithRed:(185.0/255.0) green:(227.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  网络"];
        }else if (section == 2){
//            titlelab.backgroundColor = [UIColor colorWithRed:(225.0/255.0) green:(225.0/255.0) blue:(225.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  音频"];
        }else if (section == 3){
//            titlelab.backgroundColor = [UIColor colorWithRed:(208.0/255.0) green:(150.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  视频"];
        }else if (section == 4){
//            titlelab.backgroundColor = [UIColor colorWithRed:(185.0/255.0) green:(227.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  CPU占比"];
            
        }else{
            return nil;
        }
    } else if (tableView.tag == 1001){
        if (section == 0) {
//            titlelab.backgroundColor = [UIColor colorWithRed:(208.0/255.0) green:(150.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  版本"];
            
        } else if(section == 1){
//            titlelab.backgroundColor = [UIColor colorWithRed:(185.0/255.0) green:(227.0/255.0) blue:(145.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  媒体设备"];
        }else{
//            titlelab.backgroundColor = [UIColor colorWithRed:(225.0/255.0) green:(225.0/255.0) blue:(225.0/255.0) alpha:1.0f];
            titlelab.text = [NSString stringWithFormat:@"  网络穿透"];
           
        }
    }
    titlelab.backgroundColor = [UIColor colorWithRed:(56.0/255.0) green:(61.0/255.0) blue:(121.0/255.0) alpha:1.0f];

     return titlelab;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UITableViewCell*)_beforeCalledStatsViewWithindex:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    UITableViewCell*  cell = [tableView dequeueReusableCellWithIdentifier:
            beforeLogTableViewCell forIndexPath:indexPath];
    UILabel *stateLab;
    UILabel * rightlab;
    if (cell.contentView.subviews.count > 0) {
        stateLab = [[cell.contentView subviews] firstObject];
        stateLab.text = @"";
    }else{
        stateLab = [[UILabel alloc]init];
        stateLab.frame = CGRectMake(20, 0, cell.frame.size.width, cell.frame.size.height);
        [cell.contentView addSubview:stateLab];
        stateLab.numberOfLines = 0;
        stateLab.font = [UIFont systemFontOfSize:14];
        stateLab.backgroundColor = [UIColor clearColor];
        
        rightlab = [[UILabel alloc]init];
        rightlab.backgroundColor = [UIColor clearColor];
        CGFloat width = 245;
        rightlab.frame = CGRectMake(cell.frame.size.width - width - 25, 0, width, 45);
        [cell.contentView addSubview:rightlab];
        rightlab.numberOfLines = 0;
        rightlab.textAlignment = NSTextAlignmentRight;
        rightlab.font = [UIFont systemFontOfSize:14];
        rightlab.textColor = [UIColor blackColor];
    }
    cell.contentView.backgroundColor = [UIColor colorWithRed:(244.0/255.0) green:(244.0/255.0) blue:(244.0/255.0) alpha:1.0f];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:{
                stateLab.text = @"客户端";
                NSString *appVersion;
                NSString *sdkVersionUI;
                if ([_logBeforeDic objectForKey:@"appVersion"]) {
                    appVersion = [_logBeforeDic objectForKey:@"appVersion"];
                    sdkVersionUI = [_logBeforeDic objectForKey:@"sdkVersionUI"];
                }
                rightlab.text = [NSString stringWithFormat:@"%@/%@",appVersion,sdkVersionUI];
            }
                break;
            case 1:
                stateLab.text = @"服务端";
                rightlab.text = @"0.0.0";
                break;
            default:
                break;
        }
    } else if(indexPath.section == 1){
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"麦克风";
                if ([_logBeforeDic objectForKey:@"mic"]) {
                    NSString *mic = [_logBeforeDic objectForKey:@"mic"];
                    if ([mic isEqualToString:@"true"]) {
                        rightlab.text = @"✔️";
                    }else{
                        rightlab.text = @"❌";
                    }
                }else{
                    rightlab.text = @"❌";
                }
                break;
                //                case 1:
                //                    stateLab.text = @"外放";
                //                    rightlab.text = @"✔️";
                //                    break;
                //                case 2:
                //                    stateLab.text = @"蓝牙";
                //                    rightlab.text = @"✔️";
                //                    break;
            case 1:
                stateLab.text = @"摄像头";
                if ([_logBeforeDic objectForKey:@"camera"]) {
                    NSString *mic = [_logBeforeDic objectForKey:@"camera"];
                    if ([mic isEqualToString:@"true"]) {
                        rightlab.text = @"✔️";
                    }else{
                        rightlab.text = @"❌";
                    }
                }else{
                    rightlab.text = @"❌";
                }
                break;
            default:
                break;
        }
    }else{
        switch (indexPath.row) {
            case 0:{
                stateLab.text = @"服务地址";
                NSString *stunAddr;
                if ([_logBeforeDic objectForKey:@"stunAddr"]) {
                    stunAddr = [_logBeforeDic objectForKey:@"stunAddr"];
                }
                rightlab.text = [NSString stringWithFormat:@"%@",stunAddr];
            }
                break;
            case 1:
                stateLab.text = @"SDP状态(relay)";
                if ([_logBeforeDic objectForKey:@"relay"]) {
                    NSString *mic = [_logBeforeDic objectForKey:@"relay"];
                    if ([mic isEqualToString:@"true"]) {
                        rightlab.text = @"✔️";
                    }else{
                        rightlab.text = @"❌";
                    }
                }else{
                    rightlab.text = @"❌";
                }
                break;
            case 3:
                stateLab.text = @"SDP状态(host)";
                if ([_logBeforeDic objectForKey:@"host"]) {
                    NSString *mic = [_logBeforeDic objectForKey:@"host"];
                    if ([mic isEqualToString:@"true"]) {
                        rightlab.text = @"✔️";
                    }else{
                        rightlab.text = @"❌";
                    }
                }else{
                    rightlab.text = @"❌";
                }
                break;
            case 2:
                stateLab.text = @"SDP状态(srflx)";
                if ([_logBeforeDic objectForKey:@"srflx"]) {
                    NSString *mic = [_logBeforeDic objectForKey:@"srflx"];
                    if ([mic isEqualToString:@"true"]) {
                        rightlab.text = @"✔️";
                    }else{
                        rightlab.text = @"❌";
                    }
                }else{
                    rightlab.text = @"❌";
                }
                break;
            default:
                break;
        }
    }
    return cell;
}
- (UITableViewCell*)chatingViewToStatsViewWithindex:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:
            statesLogCell forIndexPath:indexPath];
    if (!_logMsgDic) {
        return cell;
    }
    cell.contentView.backgroundColor = [UIColor colorWithRed:(244.0/255.0) green:(244.0/255.0) blue:(244.0/255.0) alpha:1.0f];
    UILabel *stateLab;
    UILabel * rightlab;
    if (cell.contentView.subviews.count > 0) {
        for (UIView *subView in cell.contentView.subviews) {
            if (subView.tag == 1003) {
                stateLab = (UILabel*)subView;
                stateLab.text = @"";
            } else if (subView.tag == 1004) {
                rightlab = (UILabel*)subView;
                rightlab.text = @"";
            }else{
                return cell;
            }
        }
        
    }else{
        if (indexPath.section != 5) {
            stateLab = [[UILabel alloc]init];
            stateLab.backgroundColor = [UIColor clearColor];
            stateLab.frame = CGRectMake(20, 0, 200, cell.frame.size.height);
            [cell.contentView addSubview:stateLab];
            stateLab.numberOfLines = 0;
            stateLab.font = [UIFont systemFontOfSize:14];
            stateLab.textColor = [UIColor blackColor];
            stateLab.tag = 1003;
            
            rightlab = [[UILabel alloc]init];
            rightlab.tag = 1004;
            rightlab.backgroundColor = [UIColor clearColor];
            CGFloat width = 245;
            rightlab.frame = CGRectMake(cell.frame.size.width - width - 25, 0, width, cell.frame.size.height);
            [cell.contentView addSubview:rightlab];
            rightlab.numberOfLines = 0;
            rightlab.textAlignment = NSTextAlignmentRight;
            rightlab.font = [UIFont systemFontOfSize:14];
            rightlab.textColor = [UIColor blackColor];
        }
        
    }
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                if (_states == 2) {//多人stats信息显示
                    stateLab.text = @"rtt";
                    rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"connRtt"]];
                    
                }else{
                    stateLab.text = @"分辨率";
                    rightlab.text = [NSString stringWithFormat:@"%@X%@",_logMsgDic[@"videoRecvWidth"],_logMsgDic[@"videoRecvHeight"]];
                    
                    
                }
                break;
            case 1:
                stateLab.text = @"码率";
                if (_states == 2) {//多人stats信息显示
                    rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"connRecvBitrate"]];
                    
                }else{
                    rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"videoSendBitrate"]];
                    
                }
                break;
            case 2:
                stateLab.text = @"帧率";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"videoSendFps"]];
                
                break;
                //                case 3:
                //                    stateLab.text = @"回音消除";
                //                    rightlab.text = [NSString stringWithFormat:@"%@",@"软解"];//_logMsgDic[@"audioSendGoogRtt"]];
                //                    break;
            default:
                break;
        }
    }else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"信令响应时间";
                rightlab.text = [NSString stringWithFormat:@"%ldms",(long)[_logBeforeDic[@"sendTime"] integerValue]];
                break;
            case 1:
                stateLab.text = @"网络协商时间";
                rightlab.text = [NSString stringWithFormat:@"%ldms",(long)[_logBeforeDic[@"stunTime"] integerValue]];
                break;
            case 2:
                stateLab.text = @"网络穿透类型";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"candia"]];
                
                break;
            case 3:{
                stateLab.text = @"网络状态";
                NSInteger rtt =  [_logMsgDic[@"audioSendGoogRtt"] integerValue];
                NSString *netState;
                if (rtt < 20) {
                    netState = @"良好";
                } else if (20 < rtt && rtt < 100) {
                    netState = @"弱网";
                }else{
                    netState = @"较差";
                }
                rightlab.text = netState;
            }
                break;
            case 4:
//                [resultDic setObject:localeCandiaType forKey:@"localCandType"];
//                [resultDic setObject:remoteCandiaType forKey:@"remotecandia"];
                stateLab.text = @"网络穿透类型远端";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"remotecandia"]];
                
                break;
            case 5:
                stateLab.text = @"网络穿透类型本地";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"localCandType"]];
                
                break;
            default:
                break;
        }
    }else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"丢包率";
                rightlab.text = [NSString stringWithFormat:@"%@%%",_logMsgDic[@"reciveAudioPacketsLostRate"]];
                break;
            case 1:
                stateLab.text = @"往返时间RTT";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"audioSendGoogRtt"]];
                if (_rttLineGraphView) {
                    //设置完数据等属性后绘图折线图
                    [_rttLineGraphView setXMarkY:@([_logMsgDic[@"audioSendGoogRtt"] integerValue]) lineId:[NSString stringWithFormat:@"%d",0]];
                    [_rttLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",0]];
                }
                break;
                
            default:
                break;
        }
    }else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"丢包率";
                rightlab.text = [NSString stringWithFormat:@"%@%%",_logMsgDic[@"reciveVideoPacketsLostRate"]];
                
                break;
            case 1:
                stateLab.text = @"往返时间RTT";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"videoSendGoogRtt"]];
                if (_rttLineGraphView) {
                    //设置完数据等属性后绘图折线图
                    [_rttLineGraphView setXMarkY:@([_logMsgDic[@"videoSendGoogRtt"] integerValue]) lineId:[NSString stringWithFormat:@"%d",1]];
                    [_rttLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",1]];
                }
                break;
            default:
                break;
        }
    }else if (indexPath.section == 4){
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"cpu使用率";
                rightlab.text = [NSString stringWithFormat:@"%@%%",_logMsgDic[@"cpuRate"]];
                break;
            default:
                break;
        }
    }else if (indexPath.section == 5){
        switch (indexPath.row) {
            case 0:
                [self setupRttlineViewWithView:cell.contentView];
                break;
            default:
                break;
        }
    }
    return cell;
}
//多人呼叫中页面
- (UITableViewCell*)mutChatingViewToStatsViewWithindex:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:
                             statesLogCell forIndexPath:indexPath];
    if (!_logMsgDic) {
        return cell;
    }
    cell.contentView.backgroundColor = [UIColor colorWithRed:(244.0/255.0) green:(244.0/255.0) blue:(244.0/255.0) alpha:1.0f];
    UILabel *stateLab;
    UILabel * rightlab;
    if (cell.contentView.subviews.count > 0) {
        for (UIView *subView in cell.contentView.subviews) {
            if (subView.tag == 1003) {
                stateLab = (UILabel*)subView;
                stateLab.text = @"";
            } else if (subView.tag == 1004) {
                rightlab = (UILabel*)subView;
                rightlab.text = @"";
            }else{
                return cell;
            }
        }
        
    }else{
        if (indexPath.section != 5) {
            stateLab = [[UILabel alloc]init];
            stateLab.backgroundColor = [UIColor clearColor];
            stateLab.frame = CGRectMake(20, 0, 200, cell.frame.size.height);
            [cell.contentView addSubview:stateLab];
            stateLab.numberOfLines = 0;
            stateLab.font = [UIFont systemFontOfSize:14];
            stateLab.textColor = [UIColor blackColor];
            stateLab.tag = 1003;
            
            rightlab = [[UILabel alloc]init];
            rightlab.tag = 1004;
            rightlab.backgroundColor = [UIColor clearColor];
            CGFloat width = 245;
            rightlab.frame = CGRectMake(cell.frame.size.width - width - 25, 0, width, cell.frame.size.height);
            [cell.contentView addSubview:rightlab];
            rightlab.numberOfLines = 0;
            rightlab.textAlignment = NSTextAlignmentRight;
            rightlab.font = [UIFont systemFontOfSize:14];
            rightlab.textColor = [UIColor blackColor];
        }
        
    }
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:{
                stateLab.text = @"rtt";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"connRtt"]];
            }
                break;
            case 1:{
                stateLab.text = @"码率";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"connRecvBitrate"]];
            }
                break;
            default:
                break;
        }
    }else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"网络穿透类型";
                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"candia"]];
                
                break;
            case 1:{
                stateLab.text = @"网络状态";
                NSInteger rtt =  [_logMsgDic[@"audioSendGoogRtt"] integerValue];
                NSString *netState;
                if (rtt < 20) {
                    netState = @"良好";
                } else if (20 < rtt && rtt < 100) {
                    netState = @"弱网";
                }else{
                    netState = @"较差";
                }
                rightlab.text = netState;
                break;
            }
            case 2:{
                stateLab.text = @"网络IP";
                rightlab.text = _logMsgDic[@"ipAddress"];
                break;
            }
            case 3:{
                stateLab.text = @"网络类型";
                rightlab.text = _logMsgDic[@"networkType"];
                break;
            }
            default:
                break;
        }
    }else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"丢包率";
                rightlab.text = [NSString stringWithFormat:@"%@%%",_logMsgDic[@"reciveAudioPacketsLostRate"]];
                break;
//            case 1:
//                stateLab.text = @"往返时间RTT";
//                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"audioSendGoogRtt"]];
//                if (_rttLineGraphView) {
//                    //设置完数据等属性后绘图折线图
//                    [_rttLineGraphView setXMarkY:@([_logMsgDic[@"audioSendGoogRtt"] integerValue]) lineId:[NSString stringWithFormat:@"%d",0]];
//                    [_rttLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",0]];
//                }
//                break;
                
            default:
                break;
        }
    }else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0:
                stateLab.text = @"丢包率";
                rightlab.text = [NSString stringWithFormat:@"%@%%",_logMsgDic[@"reciveVideoPacketsLostRate"]];
                
                break;
//            case 1:
//                stateLab.text = @"往返时间RTT";
//                rightlab.text = [NSString stringWithFormat:@"%@",_logMsgDic[@"videoSendGoogRtt"]];
//                if (_rttLineGraphView) {
//                    //设置完数据等属性后绘图折线图
//                    [_rttLineGraphView setXMarkY:@([_logMsgDic[@"videoSendGoogRtt"] integerValue]) lineId:[NSString stringWithFormat:@"%d",1]];
//                    [_rttLineGraphView reloadDatasWithLineId:[NSString stringWithFormat:@"%d",1]];
//                }
//                break;
            default:
                break;
        }
    }
    return cell;
}
-(void)dealloc{
    NSLog(@"hosten RTCStatesViewController ---dealloc");
}
/*网络穿透
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
