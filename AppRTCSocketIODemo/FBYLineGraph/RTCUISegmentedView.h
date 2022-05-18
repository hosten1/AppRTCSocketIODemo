//
//  RTCUISegmentedView.h
//  VIMRTCChatUI
//
//  Created by ymluo on 2018/8/9.
//  Copyright © 2018年 ymluo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTCUISegmentedView : UIView
/**
 *  init方法
 *
 *  @param titles   title数组 :@[@"选项1",@"选项2"]
 *  @param frame    整个naviView frame
 *  @param index    默认选中哪一个
 *  @return RTCUISegmentedView实例
 */
- (instancetype)initWithNumberOfTitles:(NSArray *)titles andFrame:(CGRect)frame defauleSelectIndex:(NSInteger)index;
- (void)onSelectIndex:(void(^)(NSInteger index))selCb;
@end
