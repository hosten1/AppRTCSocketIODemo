//
//  AppDelegate.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "AppDelegate.h"

#import "RTCLYMUtiles.h"

@interface AppDelegate ()
@property(nonatomic, strong) RTCLYMUtiles *utiles;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
   self.utiles = [[RTCLYMUtiles alloc]init];
    [_utiles openAuthersOfMICWithBlock:^(BOOL author) {
        if (!author) {
            //  没有音频权限直接退出应用
            exit(-1);
        }
    }];
    [_utiles openAuthersOfCarmarWithOptBlock:^(BOOL isSelectedYes) {
        
    }];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
