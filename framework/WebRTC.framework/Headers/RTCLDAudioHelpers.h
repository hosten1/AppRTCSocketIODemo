//
//  LDRTCResample.h
//  sources
//
//  Created by luoyongmeng on 2022/9/27.
//

#import <Foundation/Foundation.h>
#import "RTCMacros.h"
NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT
// #define kRTCUSERESAMPLE
@interface RTCLDAudioHelpers : NSObject

// #ifdef kRTCUSERESAMPLE
- (int)InitializeIfNeededWithsrcSampleRateHz:(int)src_sample_rate_hz
                          dst_sample_rate_hz:(int)dst_sample_rate_hz
                                num_channels:(size_t)num_channels;

- (void)WriteFileWithWriteFile:(NSString*)writeFilePath
            dst_sample_rate_hz:(int)dst_sample_rate_hz
                  num_channels:(size_t)num_channels;

/// 理论 上来说 WebRTC这里只能处理10ms 的音频数据，如果需要支持任意长度的数据需要修改接口
/// - Parameters:
///   - src_data: 源数据
///   - src_length: 源数据长度
///   - dst: 重采样后的数据
///   - dst_capacity: 重采样后数据的大小
///   - return: 返回实际重采样后数据的大小
- (int)resampleAudioWithInData:(const int16_t*)src_data
                    src_length:(const size_t)src_length
                           dst:(int16_t*)dst
                  dst_capacity:(size_t)dst_capacity;
//- (void) stop;
// #else
- (void)readFileWithOnWavFilePath:(NSString*)onWavFilePath
                   twoWavFilePath:(NSString*)twoWavFilePath
                        writeFile:(NSString*)writeFilePath;

- (void)readWavFileWithWavFilePath:(NSString*)onWavFilePath
                           delayMs:(int16_t)delayMs
                  audioInfoHandler:(void (^)(const size_t sampleRate,
                                             const size_t channel))audioInfoHandler
                            dataCB:(void (^)(const int16_t* dstData,
                                             size_t size,
                                             const size_t sampleRate,
                                             const size_t channel))dataCallback;

- (void)readWavFileThatUseGCDTimerWithWavFilePath:(NSString*)onWavFilePath
                                   targetdDelayMs:(int16_t)targetdDelayMs
                                 audioInfoHandler:(void (^)(const size_t sampleRate,
                                                            const size_t channel))audioInfoHandler
                                           dataCB:(void (^)(const int16_t* dstData,
                                                            size_t size,
                                                            const size_t sampleRate,
                                                            const size_t channel))dataCallback;

- (void)stop;
// #endif

@end

NS_ASSUME_NONNULL_END
