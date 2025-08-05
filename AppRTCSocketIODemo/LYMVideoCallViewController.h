//
//  LYMVideoCallViewController.h
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2025/8/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LYMVideoCallViewController : UIViewController
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *roomId;
@property (nonatomic, strong) NSString *userId;
@end

NS_ASSUME_NONNULL_END
