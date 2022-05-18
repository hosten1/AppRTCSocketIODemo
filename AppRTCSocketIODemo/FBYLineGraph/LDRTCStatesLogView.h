//
//  LDRTCStatesLogView.h
//  VIMVAChatKit
//
//  Created by ymluo on 2017/11/6.
//  Copyright © 2017年 Hosten_lym. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^clsed)(BOOL isClose);
@interface LDRTCStatesLogView : NSObject
@property(nonatomic,readonly)BOOL isHiddent;
@property(nonatomic, readonly) UIWindow *popWindows;


/**
 初始化

 @param titles 标题
 @param isCall 主叫
 //@param states 1:显示呼叫前 2：显示呼叫中 0：两个都显示
 @return 实例
 */
- (instancetype)initWithTitles:(NSArray<NSString*>*)titles isCall:(BOOL)isCall stats:(NSInteger)states;

- (void)updateLogMsgWithDictionary:(NSDictionary*)dicStates;
/**
 呼叫前的状态
 
 @param dicStates 呼叫前状态
 */
- (void)updateAVBeforeWithDictionary:(NSDictionary*)dicStates;
- (void)showStatesView;
- (void)closeStatesView;
-(void)onViewControllerClose:(clsed)close;

@end
