//
//  RTCLDWavReader.h
//  sources
//
//  Created by luoyongmeng on 2024/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^RTCWavReaderDataBlock)(NSData *data, int sampleRate, int channels, int bitsPerSample);
@interface RTCLDWavReader : NSObject
@property (nonatomic, readonly) int sampleRate;
@property (nonatomic, readonly) int channels;
@property (nonatomic, readonly) int bitsPerSample;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)startReadingWithinterval:(NSTimeInterval)interval  bufferLength:(NSUInteger)bufferLength dataCallback:(RTCWavReaderDataBlock)dataCallback;
- (void)stopReading;

@end

NS_ASSUME_NONNULL_END
