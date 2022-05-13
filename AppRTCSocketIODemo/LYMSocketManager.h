//
//  LYMSocketManager.h
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import <Foundation/Foundation.h>


//#import "RTCVPSocketIO.h"
//#import "RTCVPSocketAckEmitter.h"
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
NS_ASSUME_NONNULL_BEGIN
typedef void(^emitResp)(NSInteger code,NSDictionary* data);
typedef void(^notifyInfoCB)(NSString* __nonnull emit,NSString* __nullable data1,NSString* __nullable data2,id __nullable data , emitResp __nullable resp);


@interface LYMSocketManager : NSObject

- (void)connectionSocketWithServerUrl:(NSString* __nonnull)serverUrl isHttps:(BOOL)isHttps params: (NSDictionary* __nullable)connectParams;
- (void)joinwihtRoomId:(NSString* __nonnull)roomId name:(NSString* __nullable)name;
- (void)sendMessage:(NSDictionary* __nonnull)message withMethod:(NSString* __nonnull)method;
- (void)sendMessageWithInfo:(NSString*)info message:(NSDictionary*)message withMethod:(NSString*)method;

- (void)listenWithCB:(notifyInfoCB)notifyInfo;
- (void)close;

@end

NS_ASSUME_NONNULL_END
