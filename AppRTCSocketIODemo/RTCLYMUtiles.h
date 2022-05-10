//
//  RTCLYMUtiles.h
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTCLYMUtiles : NSObject
/**
 判断摄像头权限是否打开
 
 @return 都打开返回yes
 */
-(BOOL)openAuthersOfCarmarWithOptBlock:(void (^)(BOOL isSelectedYes)) isOpen;


/**
 判断麦风权限
 
 @param open 回调函数
 */
-(void)openAuthersOfMICWithBlock:(void (^)(BOOL author)) open;
@end

NS_ASSUME_NONNULL_END
