//
//  LDRTCStatesLogView.m
//  VIMVAChatKit
//
//  Created by ymluo on 2017/11/6.
//  Copyright © 2017年 Hosten_lym. All rights reserved.
//

#import "LDRTCStatesLogView.h"
#import "RTCStatesViewController.h"

@interface LDRTCStatesLogView()
@property(nonatomic,assign)BOOL isHiddent;
@property(nonatomic, assign) BOOL isCallVc;
@property(nonatomic, strong) UIWindow *popWindows;
@property(nonatomic, strong) UISegmentedControl *segmentedControl;

@property(nonatomic, strong) UINavigationController *nc;
@property(nonatomic, strong) RTCStatesViewController *stateVc;
@property(nonatomic, copy)   clsed closedCB;
@property(nonatomic, strong) NSArray<NSString*>* titles;
@property(nonatomic, assign) NSInteger stats;

@end

@implementation LDRTCStatesLogView
-(void)getPopWindows{
    if (!_popWindows) {
        _popWindows = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _popWindows.windowLevel = UIWindowLevelStatusBar;
        _popWindows.tag = 10010;
    }
}

- (void)setUpSegmentedControlWithFram:(CGRect)frame{
    if (!_stateVc) {
        RTCStatesViewController *stateVc = [[RTCStatesViewController alloc] initWithStates:_stats titles:_titles];
        stateVc.view.backgroundColor = [UIColor whiteColor];
        _nc = [[UINavigationController alloc]initWithRootViewController:stateVc];
        _stateVc = stateVc;
        __weak typeof(self) weakSelf = self;
        [_stateVc onViewControllerClose:^(BOOL isClose) {
            [weakSelf closeStatesView];
        }];
    }
}
-(instancetype)initWithTitles:(NSArray<NSString *> *)titles isCall:(BOOL)isCall stats:(NSInteger)states{
    self = [super init];
    if (self) {
        self.stats = states;
        self.isCallVc = isCall;
        self.titles   = titles;
    }
    return self;
}

-(void)updateLogMsgWithDictionary:(NSDictionary *)dicStates{
    if (_stateVc) {
        [_stateVc updateLogMsgWithDictionary:dicStates];
    }
}
-(void)updateAVBeforeWithDictionary:(NSDictionary *)dicStates{
    if (_stateVc) {
        [_stateVc updateAVBeforeWithDictionary:dicStates];
    }
}
-(void)showStatesView{
    _isHiddent = NO;
    [self getPopWindows];
    [self setUpSegmentedControlWithFram:CGRectMake(0, 0, _popWindows.frame.size.width, _popWindows.frame.size.height)];
    [_popWindows makeKeyAndVisible];
    _popWindows.rootViewController = _nc;
    
}
- (void)closeStatesView{
    if (_closedCB) {
        _closedCB(YES);
    }
    _isHiddent = YES;
    if (_popWindows) {
        _stateVc = nil;
        _nc = nil;
        _popWindows.frame = CGRectZero;
        _popWindows = nil;
    }
}
-(void)onViewControllerClose:(clsed)close{
    if (close) {
        _closedCB = close;
    }
}
-(void)dealloc{
    NSLog(@"LDRTCStatesLogView is dealloc with VIMVAChatKit -------------------->hosten \n");
}
@end
