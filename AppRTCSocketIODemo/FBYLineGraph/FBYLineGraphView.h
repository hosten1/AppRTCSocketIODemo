//
//  FBYLineGraphView.h
//  FBYDataDisplay-iOS
//
//  Created by fby on 2018/1/18.
//  Copyright © 2018年 FBYDataDisplay-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBYLineGraphView : UIView


/**
 *  表名
 */
@property (nonatomic, strong) NSString *title;

/**
 *  Y轴刻度标签title
 */
@property (nonatomic, strong) NSArray *yMarkTitles;
/**
 *  X轴刻度标签title
 */
@property (nonatomic, strong) NSArray *xMarkTitles;
/**
 *  Y轴最大值
 */
@property (nonatomic, assign) CGFloat maxValue;

/**
 *  X轴刻度标签的长度（单位长度）
 */
@property (nonatomic, assign) CGFloat xScaleMarkLEN;

/**
 需要绘制几条线
 */
@property (nonatomic, assign) NSInteger lineCont;
/**
 *  设置折线图显示的数据和对应X坐标轴刻度标签
 *
 *  @param yValue             数据 (如:80)
 */
- (void)setXMarkY:(NSNumber *)yValue lineId:(NSString*)lineID;

- (void)mappingWithLineId:(NSString*)lineID lineColor:(UIColor*)color;

- (void)reloadDatasWithLineId:(NSString*)lineID;
- (void)closeView;
@end
