//
//  RTCLDAudioCaptureSimulator.h
//  framework_objc
//
//  Created by luoyongmeng on 2024/6/13.
//

#import <Foundation/Foundation.h>
#import "RTCMacros.h"

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT
@interface RTCLDAudioCaptureSimulator : NSObject
- (instancetype)initWithSampleRate:(size_t)sampleRate channels:(size_t)channels intervalMs:(int)intervalMs;

// Method to start audio simulation
- (void)onAuido10msDataCallback:(void(^)(  NSData *_Nullable data))callback;

// Method to stop audio simulation
- (void)stopAudioSimulation;

// Method to add audio data
- (void)addAudioDataWithData:( NSData*)data;

- (void)clearData;

@end

NS_ASSUME_NONNULL_END
