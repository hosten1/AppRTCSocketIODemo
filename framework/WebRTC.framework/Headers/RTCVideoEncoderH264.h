/*
 *  Copyright 2017 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>

#import "RTCMacros.h"
#import "RTCVideoCodecInfo.h"
#import "RTCVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@class RTCVideoFrame;

typedef void(^RTCSampleBufferFromRTCFrameCallBack)(CVPixelBufferRef imageBuffer,
CMTime presentationTimeStamp,CMTime duration,CFDictionaryRef frameProperties);
RTC_OBJC_EXPORT
@interface RTCVideoEncoderH264 : NSObject <RTCVideoEncoder>
@property(nonatomic, assign) int index;
- (instancetype)initWithCodecInfo:(RTCVideoCodecInfo *)codecInfo;

- (instancetype)initWithCodecInfo:(RTCVideoCodecInfo *)codecInfo isUserEncod:(BOOL)isUserEncod;

- (NSInteger)sampleBufferFromRTCFrame:(RTCVideoFrame *)frame
codecSpecificInfo:(id<RTCCodecSpecificInfo>)codecSpecificInfo
                           frameTypes:(NSArray<NSNumber *> *)frameTypes sampleBufferCB:(RTCSampleBufferFromRTCFrameCallBack)sampleBufferCb;
@end
