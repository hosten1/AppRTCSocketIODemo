//
//  FBYLineGraphContentView.h
//  FBYDataDisplay-iOS
//
//  Created by fby on 2018/1/18.
//  Copyright © 2018年 FBYDataDisplay-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBYLineGraphBaseView.h"

@interface FBYLineGraphContentView : FBYLineGraphBaseView

@property(nonatomic,strong)NSMutableDictionary *yValues;


/**
 *  绘图
 */
- (void)mappingWithLineId:(NSString *)lineID lineColor:(UIColor*)color;

/**
 *  更新折线图数据
 */
- (void)reloadDatasWithLineId:(NSString *)lineID;
-(void)closeView;
@end
