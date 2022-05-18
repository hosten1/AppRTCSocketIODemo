//
//  RTCStatesViewController.h
//  VIMRTCChatUI
//
//  Created by ymluo on 2018/7/30.
//  Copyright © 2018年 ymluo. All rights reserved.
//

#import <UIKit/UIKit.h>

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

typedef void(^clsed)(BOOL isClose);

@interface RTCStatesViewController : UIViewController

/**
 初始化

 @param states 1:显示呼叫前 2：显示呼叫中 0：两个都显示
 @return 实例
 */
-(instancetype)initWithStates:(NSInteger)states titles:(NSArray<NSString*>*)titles;
-(void)onViewControllerClose:(clsed)close;
- (void)updateLogMsgWithDictionary:(NSDictionary*)dicStates;

/**
 呼叫前的状态

 @param dicStates 呼叫前状态
 */
- (void)updateAVBeforeWithDictionary:(NSDictionary*)dicStates;
@end
