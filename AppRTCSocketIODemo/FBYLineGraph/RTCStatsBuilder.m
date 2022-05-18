/*
 *  Copyright 2015 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "RTCStatsBuilder.h"
#import "WebRTC/RTCLegacyStatsReport.h"
#import "RTCBitrateTracker.h"

@interface RTCStatsBuilder ()
/// Connection stats.
@property(nonatomic,copy)NSString *connRecvBitrate;
@property(nonatomic,copy)NSString *connRtt;
@property(nonatomic,copy)NSString *connSendBitrate;
@property(nonatomic,copy)NSString *localCandType;
@property(nonatomic,copy)NSString *remoteCandType;
@property(nonatomic,copy)NSString *transportType;
@property(nonatomic,strong)NSNumber *connRecvBitrateNum;
@property(nonatomic,strong)NSNumber *connSendBitrateNum;

// BWE stats.
@property(nonatomic,copy)NSString *actualEncBitrate;
@property(nonatomic,copy)NSString *availableRecvBw;
@property(nonatomic,copy)NSString *availableSendBw;
@property(nonatomic,copy)NSString *targetEncBitrate;

// Video send stats.
@property(nonatomic,copy)NSString *videoEncodeMs;
@property(nonatomic,copy)NSString *videoInputFps;
@property(nonatomic,copy)NSString *videoInputHeight;
@property(nonatomic,copy)NSString *videoInputWidth;
@property(nonatomic,copy)NSString *videoSendCodec;
@property(nonatomic,copy)NSString *videoSendBitrate;
@property(nonatomic,copy)NSString *videoSendFps;
@property(nonatomic,copy)NSString *videoSendHeight;
@property(nonatomic,copy)NSString *videoSendWidth;
@property(nonatomic,copy)NSString *videoSendGoogRtt;

// QP stats.
@property(nonatomic,assign)int videoQPSum;
@property(nonatomic,assign)int framesEncoded;
@property(nonatomic,assign)int oldVideoQPSum;
@property(nonatomic,assign)int oldFramesEncoded;

// Video receive stats.
@property(nonatomic,copy)NSString *videoDecodeMs;
@property(nonatomic,copy)NSString *videoDecodedFps;
@property(nonatomic,copy)NSString *videoOutputFps;
@property(nonatomic,copy)NSString *videoRecvBitrate;
@property(nonatomic,copy)NSString *videoRecvFps;
@property(nonatomic,copy)NSString *videoRecvHeight;
@property(nonatomic,copy)NSString *videoRecvWidth;

// Audio send stats.
@property(nonatomic,copy)NSString *audioSendBitrate;
@property(nonatomic,copy)NSString *audioSendCodec;
@property(nonatomic,copy)NSString *audioSendGoogRtt;

// Audio receive stats.
@property(nonatomic,copy)NSString *audioCurrentDelay;
@property(nonatomic,copy)NSString *audioExpandRate;
@property(nonatomic,copy)NSString *audioRecvBitrate;
@property(nonatomic,copy)NSString *audioRecvCodec;

// Bitrate trackers.
@property(nonatomic,strong)RTCBitrateTracker *audioRecvBitrateTracker;
@property(nonatomic,strong)RTCBitrateTracker *audioSendBitrateTracker;
@property(nonatomic,strong)RTCBitrateTracker *connRecvBitrateTracker;
@property(nonatomic,strong)RTCBitrateTracker *connSendBitrateTracker;
@property(nonatomic,strong)RTCBitrateTracker *videoRecvBitrateTracker;
@property(nonatomic,strong)RTCBitrateTracker *videoSendBitrateTracker;

@property(nonatomic,copy)NSString *  sendVideoPacketsLost;
@property(nonatomic,copy)NSString *  reviceVideoPacketsLost;
@property(nonatomic,copy)NSString *  sendVideoPackets;
@property(nonatomic,copy)NSString *  reviceVideoPackets;

@property(nonatomic,copy)NSString *  sendAudioPacketsLost;
@property(nonatomic,copy)NSString *  reviceAudioPacketsLost;
@property(nonatomic,copy)NSString *  sendAudioPackets;
@property(nonatomic,copy)NSString *  reviceAudioPackets;

@property(nonatomic,copy)NSString *  googJitterBufferMs;
@end

@implementation RTCStatsBuilder
- (instancetype)init {
    if (self = [super init]) {
        _audioSendBitrateTracker = [[RTCBitrateTracker alloc] init];
        _audioRecvBitrateTracker = [[RTCBitrateTracker alloc] init];
        _connSendBitrateTracker = [[RTCBitrateTracker alloc] init];
        _connRecvBitrateTracker = [[RTCBitrateTracker alloc] init];
        _videoSendBitrateTracker = [[RTCBitrateTracker alloc] init];
        _videoRecvBitrateTracker = [[RTCBitrateTracker alloc] init];
        _videoQPSum = 0;
        _framesEncoded = 0;
    }
    return self;
}
-(NSDictionary *)statsDic{
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionary];
    [mutDic setObject:_videoSendFps?_videoSendFps:@"0fps" forKey:@"videoSendFps"];
    [mutDic setObject:_connSendBitrate?_connSendBitrate:@"0bit" forKey:@"connSendBitrate"];
    [mutDic setObject:_videoSendWidth?_videoSendWidth:@"0" forKey:@"videoSendWidth"];
    [mutDic setObject:_videoSendHeight?_videoSendHeight:@"0" forKey:@"videoSendHeight"];
    [mutDic setObject:_localCandType?_localCandType:@"locale" forKey:@"localCandType"];
    [mutDic setObject:_videoSendBitrate?_videoSendBitrate:@"0" forKey:@"videoSendBitrate"];
    [mutDic setObject:_audioSendBitrate?_audioSendBitrate:@"0" forKey:@"audioSendBitrate"];
    [mutDic setObject:_sendVideoPackets?_videoSendBitrate:@"0" forKey:@"sendVideoPackets"];
    [mutDic setObject:_sendAudioPackets?_sendAudioPackets:@"0" forKey:@"sendAudioPackets"];
    [mutDic setObject:_sendVideoPacketsLost?_sendVideoPacketsLost:@"0" forKey:@"sendVideoPacketsLost"];
    [mutDic setObject:_sendAudioPacketsLost?_sendAudioPacketsLost:@"0" forKey:@"sendAudioPacketsLost"];
    [mutDic setObject:_audioSendGoogRtt?_audioSendGoogRtt:@"0" forKey:@"audioSendGoogRtt"];
    [mutDic setObject:_videoSendGoogRtt?_videoSendGoogRtt:@"0" forKey:@"videoSendGoogRtt"];
    
    [mutDic setObject:_videoRecvFps?_videoRecvFps:@"0fps" forKey:@"videoRecvFps"];
    [mutDic setObject:_connRecvBitrate?_connRecvBitrate:@"0bit" forKey:@"connRecvBitrate"];
    [mutDic setObject:_videoRecvWidth?_videoRecvWidth:@"0" forKey:@"videoRecvWidth"];
    [mutDic setObject:_videoRecvHeight?_videoRecvHeight:@"0" forKey:@"videoRecvHeight"];
    [mutDic setObject:_remoteCandType?_remoteCandType:@"remote" forKey:@"remoteCandType"];
    [mutDic setObject:_videoRecvBitrate?_videoRecvBitrate:@"0" forKey:@"videoRecvBitrate"];
    [mutDic setObject:_audioRecvBitrate?_audioRecvBitrate:@"0" forKey:@"audioRecvBitrate"];
    [mutDic setObject:_reviceVideoPackets?_reviceVideoPackets:@"0" forKey:@"reviceVideoPackets"];
    [mutDic setObject:_reviceAudioPackets?_reviceAudioPackets:@"0" forKey:@"reviceAudioPackets"];
    [mutDic setObject:_reviceVideoPacketsLost?_reviceVideoPacketsLost:@"0" forKey:@"reviceVideoPacketsLost"];
    [mutDic setObject:_reviceAudioPacketsLost?_reviceAudioPacketsLost:@"0" forKey:@"reviceAudioPacketsLost"];
    
    [mutDic setObject:_googJitterBufferMs?_googJitterBufferMs:@"0" forKey:@"googJitterBufferMs"];
    [mutDic setObject:_connRtt?_connRtt:@"0" forKey:@"connRtt"];
    [mutDic setObject:_connRecvBitrate?_connRecvBitrate:@"0" forKey:@"connRecvBitrate"];
    [mutDic setObject:_connSendBitrate?_connSendBitrate:@"0" forKey:@"connSendBitrate"];
    
    [mutDic setObject:_connRecvBitrateNum?_connRecvBitrateNum:@"0" forKey:@"connRecvBitrateNum"];
    [mutDic setObject:_connSendBitrateNum?_connSendBitrateNum:@"0" forKey:@"connSendBitrateNum"];
    
    [mutDic setObject:_videoSendCodec?_videoSendCodec:@"0" forKey:@"videoSendCodec"];
//    NSLog(@"hsoten _audioSendGoogRtt:%@,_videoSendGoogRtt:%@,ARDGetCpuUsagePercentage:%ld",_audioSendGoogRtt,_videoSendGoogRtt,(long)ARDGetCpuUsagePercentage());
    
    return mutDic;
}
- (NSString *)statsString {
    NSMutableString *result = [NSMutableString string];
    
    // Connection stats.
    NSString *connStatsFormat = @"CN %@ms | %@->%@/%@ | (s)%@ | (r)%@\n";
    [result appendString:[NSString stringWithFormat:connStatsFormat,
                          _connRtt,
                          _localCandType, _remoteCandType, _transportType,
                          _connSendBitrate, _connRecvBitrate]];
    
    // Video send stats.
    NSString *videoSendFormat = @"VS (input) %@x%@@%@fps | (sent) %@x%@@%@fps\n"
    "VS (enc) %@/%@ | (sent) %@/%@ | %@ms | %@\n"
    "AvgQP (past %d encoded frames) = %d\n ";
    int avgqp = [self calculateAvgQP];
    
    [result appendString:[NSString stringWithFormat:videoSendFormat,
                          _videoInputWidth, _videoInputHeight, _videoInputFps,
                          _videoSendWidth, _videoSendHeight, _videoSendFps,
                          _actualEncBitrate, _targetEncBitrate,
                          _videoSendBitrate, _availableSendBw,
                          _videoEncodeMs,
                          _videoSendCodec,
                          _framesEncoded - _oldFramesEncoded, avgqp]];
    
    // Video receive stats.
    NSString *videoReceiveFormat =
    @"VR (recv) %@x%@@%@fps | (decoded)%@ | (output)%@fps | %@/%@ | %@ms\n";
    [result appendString:[NSString stringWithFormat:videoReceiveFormat,
                          _videoRecvWidth, _videoRecvHeight, _videoRecvFps,
                          _videoDecodedFps,
                          _videoOutputFps,
                          _videoRecvBitrate, _availableRecvBw,
                          _videoDecodeMs]];
    
    // Audio send stats.
    NSString *audioSendFormat = @"AS %@ | %@\n";
    [result appendString:[NSString stringWithFormat:audioSendFormat,
                          _audioSendBitrate, _audioSendCodec]];
    
    // Audio receive stats.
    NSString *audioReceiveFormat = @"AR %@ | %@ | %@ms | (expandrate)%@";
    [result appendString:[NSString stringWithFormat:audioReceiveFormat,
                          _audioRecvBitrate, _audioRecvCodec, _audioCurrentDelay,
                          _audioExpandRate]];
    
    return result;
}

- (void)parseStatsReport:(RTCLegacyStatsReport *)statsReport {
    NSString *reportType = statsReport.type;
    if ([reportType isEqualToString:@"ssrc"] &&
        [statsReport.reportId rangeOfString:@"ssrc"].location != NSNotFound) {
        if ([statsReport.reportId rangeOfString:@"send"].location != NSNotFound) {
            [self parseSendSsrcStatsReport:statsReport];
        }
        if ([statsReport.reportId rangeOfString:@"recv"].location != NSNotFound) {
            [self parseRecvSsrcStatsReport:statsReport];
        }
    } else if ([reportType isEqualToString:@"VideoBwe"]) {
        [self parseBweStatsReport:statsReport];
    } else if ([reportType isEqualToString:@"googCandidatePair"]) {
        [self parseConnectionStatsReport:statsReport];
    }
}

#pragma mark - Private

- (int)calculateAvgQP {
    int deltaFramesEncoded = _framesEncoded - _oldFramesEncoded;
    int deltaQPSum = _videoQPSum - _oldVideoQPSum;
    
    return deltaFramesEncoded != 0 ? deltaQPSum / deltaFramesEncoded : 0;
}

- (void)parseBweStatsReport:(RTCLegacyStatsReport *)statsReport {
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
        __weak typeof(self) weakSelf = self;
    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googAvailableSendBandwidth"]) {
            weakSelf.availableSendBw =
            [RTCBitrateTracker bitrateStringForBitrate:value.doubleValue];
        } else if ([key isEqualToString:@"googAvailableReceiveBandwidth"]) {
            weakSelf.availableRecvBw =
            [RTCBitrateTracker bitrateStringForBitrate:value.doubleValue];
        } else if ([key isEqualToString:@"googActualEncBitrate"]) {
            weakSelf.actualEncBitrate =
            [RTCBitrateTracker bitrateStringForBitrate:value.doubleValue];
        } else if ([key isEqualToString:@"googTargetEncBitrate"]) {
            weakSelf.targetEncBitrate =
            [RTCBitrateTracker bitrateStringForBitrate:value.doubleValue];
        }
    }];
}

- (void)parseConnectionStatsReport:(RTCLegacyStatsReport *)statsReport {
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
    NSString *activeConnection = statsReport.values[@"googActiveConnection"];
    if (![activeConnection isEqualToString:@"true"]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googRtt"]) {
            weakSelf.connRtt = value;
        } else if ([key isEqualToString:@"googLocalCandidateType"]) {
            weakSelf.localCandType = value;
        } else if ([key isEqualToString:@"googRemoteCandidateType"]) {
            weakSelf.remoteCandType = value;
        } else if ([key isEqualToString:@"googTransportType"]) {
            weakSelf.transportType = value;
        } else if ([key isEqualToString:@"bytesReceived"]) {
            NSInteger byteCount = value.integerValue;
            [weakSelf.connRecvBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
            weakSelf.connRecvBitrateNum = @(weakSelf.connRecvBitrateTracker.bitrate);
            weakSelf.connRecvBitrate = weakSelf.connRecvBitrateTracker.bitrateString;
        } else if ([key isEqualToString:@"bytesSent"]) {
            NSInteger byteCount = value.integerValue;
            [weakSelf.connSendBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
            weakSelf.connSendBitrateNum = @(weakSelf.connSendBitrateTracker.bitrate);
            weakSelf.connSendBitrate = weakSelf.connSendBitrateTracker.bitrateString;
        }
    }];
}

- (void)parseSendSsrcStatsReport:(RTCLegacyStatsReport *)statsReport {
    NSDictionary *values = statsReport.values;
    if ([values objectForKey:@"googFrameRateSent"]) {
        // Video track.
        [self parseVideoSendStatsReport:statsReport];
    } else if ([values objectForKey:@"audioInputLevel"]) {
        // Audio track.
        [self parseAudioSendStatsReport:statsReport];
    }
}

- (void)parseAudioSendStatsReport:(RTCLegacyStatsReport *)statsReport {
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
    __weak typeof(self) weakSelf = self;
    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googCodecName"]) {
            weakSelf.audioSendCodec = value;
        } else if ([key isEqualToString:@"bytesSent"]) {
            NSInteger byteCount = value.integerValue;
            [ weakSelf.audioSendBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
             weakSelf.audioSendBitrate = weakSelf.audioSendBitrateTracker.bitrateString;
        }else if ([key isEqualToString:@"packetsLost"]) {
             weakSelf.sendAudioPacketsLost = value;
        } if ([key isEqualToString:@"packetsSent"]) {
             weakSelf.sendAudioPacketsLost = value;
        }else if ([key isEqualToString:@"googRtt"]) {
             weakSelf.audioSendGoogRtt = value;
        }
    }];
}

- (void)parseVideoSendStatsReport:(RTCLegacyStatsReport *)statsReport {
    __weak typeof(self) weakSelf = self;
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googCodecName"]) {
            weakSelf.videoSendCodec = value;
        } else if ([key isEqualToString:@"googFrameHeightInput"]) {
            weakSelf.videoInputHeight = value;
        } else if ([key isEqualToString:@"googFrameWidthInput"]) {
            weakSelf.videoInputWidth = value;
        } else if ([key isEqualToString:@"googFrameRateInput"]) {
            weakSelf.videoInputFps = value;
        } else if ([key isEqualToString:@"googFrameHeightSent"]) {
            weakSelf.videoSendHeight = value;
        } else if ([key isEqualToString:@"googFrameWidthSent"]) {
            weakSelf.videoSendWidth = value;
        } else if ([key isEqualToString:@"googFrameRateSent"]) {
            weakSelf.videoSendFps = value;
        } else if ([key isEqualToString:@"googAvgEncodeMs"]) {
            weakSelf.videoEncodeMs = value;
        } else if ([key isEqualToString:@"bytesSent"]) {
            NSInteger byteCount = value.integerValue;
            [weakSelf.videoSendBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
            weakSelf.videoSendBitrate = weakSelf.videoSendBitrateTracker.bitrateString;
        } else if ([key isEqualToString:@"qpSum"]) {
            weakSelf.oldVideoQPSum = weakSelf.videoQPSum;
            weakSelf.videoQPSum = value.intValue;
        } else if ([key isEqualToString:@"framesEncoded"]) {
            weakSelf.oldFramesEncoded = weakSelf.framesEncoded;
            weakSelf.framesEncoded = value.intValue;
        }else if ([key isEqualToString:@"packetsLost"]) {
            weakSelf.sendVideoPacketsLost = value;
        }else if ([key isEqualToString:@"packetsSent"]) {
            weakSelf.sendVideoPackets = value;
        }else if ([key isEqualToString:@"googRtt"]) {
            weakSelf.videoSendGoogRtt = value;
        }
    }];
}

- (void)parseRecvSsrcStatsReport:(RTCLegacyStatsReport *)statsReport {
    
    NSDictionary *values = statsReport.values;
    if ([values objectForKey:@"googFrameWidthReceived"]) {
        // Video track.
        [self parseVideoRecvStatsReport:statsReport];
    } else if ([values objectForKey:@"audioOutputLevel"]) {
        // Audio track.
        [self parseAudioRecvStatsReport:statsReport];
    }
    if ([values objectForKey:@"googJitterBufferMs"]){
        //        NSLog(@"hosten googJitterBufferMs Func:%s %@ \n",__func__,statsReport.values[@"googJitterBufferMs"]);
        
        _googJitterBufferMs = statsReport.values[@"googJitterBufferMs"];
    }
}

- (void)parseAudioRecvStatsReport:(RTCLegacyStatsReport *)statsReport {
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
    __weak typeof(self) weakSelf = self;

    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googCodecName"]) {
            weakSelf.audioRecvCodec = value;
        } else if ([key isEqualToString:@"bytesReceived"]) {
            NSInteger byteCount = value.integerValue;
            [weakSelf.audioRecvBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
            weakSelf.audioRecvBitrate = weakSelf.audioRecvBitrateTracker.bitrateString;
        } else if ([key isEqualToString:@"googSpeechExpandRate"]) {
            weakSelf.audioExpandRate = value;
        } else if ([key isEqualToString:@"googCurrentDelayMs"]) {
            weakSelf.audioCurrentDelay = value;
        } else if ([key isEqualToString:@"packetsLost"]) {
            weakSelf.reviceAudioPacketsLost = value;
        }else if ([key isEqualToString:@"packetsReceived"]) {
            weakSelf.reviceAudioPackets = value;
        }
    }];
}

- (void)parseVideoRecvStatsReport:(RTCLegacyStatsReport *)statsReport {
    //    NSLog(@"hosten state Func:%s %@ \n\n\n",__func__,statsReport.values.description);
    __weak typeof(self) weakSelf = self;

    [statsReport.values enumerateKeysAndObjectsUsingBlock:^(
                                                            NSString *key, NSString *value, BOOL *stop) {
        if ([key isEqualToString:@"googFrameHeightReceived"]) {
             weakSelf.videoRecvHeight = value;
        } else if ([key isEqualToString:@"googFrameWidthReceived"]) {
             weakSelf.videoRecvWidth = value;
        } else if ([key isEqualToString:@"googFrameRateReceived"]) {
             weakSelf.videoRecvFps = value;
        } else if ([key isEqualToString:@"googFrameRateDecoded"]) {
             weakSelf.videoDecodedFps = value;
        } else if ([key isEqualToString:@"googFrameRateOutput"]) {
             weakSelf.videoOutputFps = value;
        } else if ([key isEqualToString:@"googDecodeMs"]) {
             weakSelf.videoDecodeMs = value;
        } else if ([key isEqualToString:@"bytesReceived"]) {
            NSInteger byteCount = value.integerValue;
            [ weakSelf.videoRecvBitrateTracker updateBitrateWithCurrentByteCount:byteCount];
             weakSelf.videoRecvBitrate =  weakSelf.videoRecvBitrateTracker.bitrateString;
        } else if ([key isEqualToString:@"packetsLost"]) {
             weakSelf.reviceVideoPacketsLost = value;
        }else if ([key isEqualToString:@"packetsReceived"]) {
             weakSelf.reviceVideoPackets = value;
        }
    }];
}

@end
