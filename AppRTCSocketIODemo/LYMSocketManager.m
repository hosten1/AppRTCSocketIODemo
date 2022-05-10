//
//  LYMSocketManager.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "LYMSocketManager.h"
#import<VPSocketIO/RTCVPSocketIO.h>



@interface LYMSocketManager ()

@property(nonatomic, strong) RTCVPSocketIOClient *socket;
@property(nonatomic,strong) dispatch_queue_t currentEngineProtooQueue;
@property (nonatomic,copy)  notifyInfoCB notifyInfo;

@end
@implementation LYMSocketManager
-(instancetype)init{
    if (self = [super init]) {
        _currentEngineProtooQueue = dispatch_queue_create("com.vrv.mediasoupProtoo", DISPATCH_QUEUE_SERIAL);
    }
    return  self;
}





-(void)connectionSocketWithServerUrl:(NSString*)serverUrl isHttps:(BOOL)isHttps params:(NSDictionary*)connect
{

    // 这个消息 是在http的消息体力包含
    NSDictionary *connectParams = @{@"version_name":@"3.2.1",
                                    @"version_code":@"43234",
                                    @"platform":@"iOS",
                                    @"mac":@"ff:44:55:dd:88",
                                    @"tesolution":@"1820*1080"
    };
    RTCVPSocketLogger *logger = [[RTCVPSocketLogger alloc]init];
    [logger onLogMsgWithCB:^(NSString *message, NSString *type) {
        if ([type isEqualToString:@"RTCVPSocketIOClient"]) {
            //忽略消息
            return;
        }else if ([type isEqualToString:@"SocketParser"] && [message containsString:@"Decoded packet as"]){
            return;
        }
        NSLog(@"==========> %@",message);
        
    }];
    self.socket = [[RTCVPSocketIOClient alloc] init:[NSURL URLWithString:serverUrl]
                                    withConfig:@{@"log": @NO,
                                                 @"reconnects":@YES,
                                                 @"reconnectAttempts":@(20),
                                                 @"forcePolling": @NO,
                                                 @"secure": @(isHttps),
                                                 @"forceNew":@YES,
                                                 @"forceWebsockets":@(YES),
                                                 @"selfSigned":@(isHttps),
                                                 @"reconnectWait":@3,
                                                 @"nsp":@"/",
                                                 @"connectParams":connectParams,
                                                 @"logger":logger
                                    }];
   WEAKSELF
    [_socket on:kSocketEventConnect callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"connect",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"connect",array[0],nil);
        }
    }];
    [_socket on:kSocketEventDisconnect callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"disconnect",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"disconnect",array[0],nil);
        }
    }];
    [_socket on:kSocketEventError callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"error",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"error",array[0],nil);
        }
    }];
    [_socket on:@"joined" callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"joined",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"joined",array[0],nil);
        }
    }];
    [_socket on:@"otherJoined" callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"otherJoined",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"otherJoined",array[0],nil);
        }
    }];
    [_socket on:@"leaved" callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"leaved",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"leaved",array[0],nil);
        }
    }];
    [_socket on:@"message" callback:^(NSArray *array, RTCVPSocketAckEmitter *emitter) {
        STRONGSELF
        if (!strongSelf.notifyInfo) {
            return;
        }
        if (array.count > 1) {
            strongSelf.notifyInfo(@"message",array[1],nil);
        }else{
            strongSelf.notifyInfo(@"message",array[0],nil);
        }
    }];
    
    [_socket connectWithTimeoutAfter:10 withHandler:^{
//        STRONGSELF
       
        NSLog(@"=======>连接超时了");
    }];
    
}
- (void)listenWithCB:(void (^)(NSString * _Nonnull, id _Nonnull, emitResp _Nonnull))notifyInfo{
    if (notifyInfo) {
        self.notifyInfo = notifyInfo;
    }
}
- (void)joinwihtRoomId:(NSString*)roomId name:(NSString*)name{
//    [self sendMessage:nil withMethod:@"join"];
//    [_socket emit:@"join" items:@[roomId]];
    RTCVPSocketOnAckCallback *callback = [_socket emitWithAck:@"join" items:@[roomId]];
    [callback timingOutAfter:10 callback:^(NSArray *array) {
        NSLog(@">>>>>>>>>ack msg:%@",array);
    }];

}
- (void)sendMessage:(NSDictionary*)message withMethod:(NSString*)method{
    
    WEAKSELF
    dispatch_async(_currentEngineProtooQueue, ^{
        @autoreleasepool {
            __strong typeof(weakSelf) blockSelf = weakSelf;
            if (!blockSelf.socket) {
               
                return;
            }
            RTCVPSocketOnAckCallback *callback = [blockSelf.socket emitWithAck:method items:@[@"123456",message]];
            [callback timingOutAfter:10 callback:^(NSArray *array) {
                NSLog(@">>>>>>>>>ack msg:%@",array);
            }];
        }
        
    });
    
}
-(void)close{
    
    [self disconnect];
}
- (void)disconnect {
    
    [self.socket removeAllHandlers];
    [self.socket disconnect];
    self.socket = nil;
    
}
@end
