//
//  RTCLDWavFileWriteHelpers.h
//  sources
//
//  Created by luoyongmeng on 2024/6/24.
//

#import <Foundation/Foundation.h>

#import "RTCMacros.h"
NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT
@interface RTCLDWavFileWriteHelpers : NSObject
+  (void) frameToFileWithFileFullPath:(NSString *)fileFullPath
                          samples: (const int16_t*)samples
                            length:(const size_t )length
                            number_of_channels:(const size_t)
                            number_of_channels
                      sample_rate:(const int) sample_rate;


/**
 * 初始化WAV文件写入器
 * @param fileFullPath WAV文件的完整路径
 * @param dst_sample_rate_hz 目标采样率（单位：Hz）
 * @param num_channels 音频通道数
 * @return 初始化后的RTCLDWavFileWriteHelpers实例
 */
- (instancetype)initWithFileFullPath:(NSString *)fileFullPath dst_sample_rate_hz:(int) dst_sample_rate_hz num_channels:(size_t) num_channels;


/**
 * 向WAV文件中添加音频数据 buffer写入
 * @param data 包含PCM音频数据的NSData对象
 */
- (void)addAudioDataToBufferWithData:( NSData*)data;

/**
 * 停止向WAV文件中添加音频数据
 */
- (void)stopAudioSimulation;


@end


NS_ASSUME_NONNULL_END
