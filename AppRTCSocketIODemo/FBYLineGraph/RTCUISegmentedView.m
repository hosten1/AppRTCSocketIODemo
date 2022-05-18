//
//  RTCUISegmentedView.m
//  VIMRTCChatUI
//
//  Created by ymluo on 2018/8/9.
//  Copyright © 2018年 ymluo. All rights reserved.
//

#import "RTCUISegmentedView.h"

#define kSelectedColor [UIColor whiteColor]
#define kNormalColor  [UIColor grayColor]
// Button进行封装
@interface LDNaviButton:UIButton

@property (nonatomic, weak) UIView *lineView;
@end

@implementation LDNaviButton

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        CGFloat lineWidth = 3;
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - lineWidth, frame.size.width, lineWidth)];
        // 设置初始状态
        lineView.backgroundColor = kNormalColor;
        //        lineView.hidden = YES;
        _lineView = lineView;
        [self setTitleColor:kNormalColor forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        [self setBackgroundColor:[UIColor clearColor]];
        [self addSubview:lineView];
    }
    return self;
}



@end
@interface RTCUISegmentedView()
@property (nonatomic, strong) LDNaviButton *lastClickButton;
@property (nonatomic, copy) void (^selCallBack)(NSInteger selIndex);

@end
@implementation RTCUISegmentedView
- (instancetype)initWithNumberOfTitles:(NSArray *)titles andFrame:(CGRect)frame defauleSelectIndex:(NSInteger)index{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat buttonWidth = frame.size.width / titles.count;
        
        for (int i = 0; i < titles.count; i ++) {
            LDNaviButton *button = [[LDNaviButton alloc] initWithFrame:CGRectMake(i *buttonWidth, 0, buttonWidth, frame.size.height)];
            // 默认选中第一个 设置状态
            if (i == index) {
                [button setTitleColor:kSelectedColor forState:UIControlStateNormal];
                button.lineView.backgroundColor = kSelectedColor;
                // 保留为上次选择中的button
                _lastClickButton = button;
            }else{
                [button setTitleColor:kNormalColor forState:UIControlStateNormal];
                button.lineView.backgroundColor = kNormalColor;
            }
            // 设置对应的tag
            button.tag = i;
            [button setTitle:titles[i] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(A_choosed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
        }
    }
    return self;
    
}

- (void)A_choosed:(LDNaviButton *)button{
    // 连续点击同一个不响应回调
    if (_lastClickButton != button) {
        // 设置状态
        [button setTitleColor:kSelectedColor forState:UIControlStateNormal];
        button.lineView.backgroundColor = kSelectedColor;
        [_lastClickButton setTitleColor:kNormalColor forState:UIControlStateNormal];
        _lastClickButton.lineView.backgroundColor = kNormalColor;
        _lastClickButton = button;
    }
    if (_selCallBack) {
        _selCallBack(button.tag);
    }
}
-(void)onSelectIndex:(void (^)(NSInteger))selCb{
    if (selCb) {
        _selCallBack = selCb;
    }
}
@end
