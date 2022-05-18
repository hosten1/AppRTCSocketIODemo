//
//  FBYLineGraphView.m
//  FBYDataDisplay-iOS
//
//  Created by fby on 2018/1/18.
//  Copyright © 2018年 FBYDataDisplay-iOS. All rights reserved.
//

#import "FBYLineGraphView.h"
#import "FBYLineGraphContentView.h"

static NSString *const kXtitleNameKey = @"titleName";
static NSString *const kYValueKey = @"yValue";

@interface FBYLineGraphView()
//@property(nonatomic,strong)NSMutableDictionary *xMarkTitlesAndValuesDic;
@property(nonatomic,strong)NSMutableDictionary *yValues;
@end

@interface FBYLineGraphView()

/**
 *  表名标签
 */
@property (nonatomic, strong) UILabel *titleLab;

/**
 *  显示折线图的可滑动视图
 */
@property (nonatomic, strong) UIScrollView *scrollView;

/**
 *  折线图
 */
@property (nonatomic, strong) FBYLineGraphContentView *lineGraphContentView;

///**
// *  X轴刻度标签 和 对应的折线图点的值
// */
//@property (nonatomic, strong) NSArray *xMarkTitlesAndValues;

@end

@implementation FBYLineGraphView
//-(NSMutableDictionary *)_xMarkTitles{
//    if (!_xMarkTitles) {
//        _xMarkTitles = [NSMutableArray array];
//    }
//    return _xMarkTitles;
//}
-(NSMutableDictionary *)yValues{
    if (!_yValues) {
        _yValues = [NSMutableDictionary dictionary];
    }
    return _yValues;
}
- (void)setXScaleMarkLEN:(CGFloat)xScaleMarkLEN {
    _xScaleMarkLEN = xScaleMarkLEN;
}

- (void)setYMarkTitles:(NSArray *)yMarkTitles {
    _yMarkTitles = yMarkTitles;
}

- (void)setMaxValue:(CGFloat)maxValue {
    _maxValue = maxValue;
    
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
}
-(void)setXMarkY:(NSNumber *)yValue lineId:(NSString *)lineID{
        if ([self.yValues.allKeys containsObject:lineID]) {
            NSMutableArray *yMarkValues =  [self.yValues[lineID] mutableCopy];
            if (yMarkValues.count > 60) {//超过屏幕宽度移除掉(超过1分钟，重新绘制)
                [yMarkValues removeAllObjects];
                
            }
            [yMarkValues addObject:yValue];
            [self.yValues setObject:yMarkValues forKey:lineID];
        }else{
            [self.yValues setObject:@[yValue] forKey:lineID];
        }
   
//    xMarkTitles = [NSMutableArray array];
//    valueArray = [NSMutableArray array];
//
//    for (NSDictionary *dic in _xMarkTitlesAndValuesMut) {
//        [xMarkTitles addObject:[dic objectForKey:kXtitleNameKey]];
//        [valueArray addObject:[dic objectForKey:yValue]];
//    }
}

#pragma mark 绘图
- (void)mappingWithLineId:(NSString *)lineID lineColor:(UIColor *)color {
    
    static CGFloat topToContainView = 0.f;
    
    if (self.title) {
        self.titleLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.frame), 20)];
        self.titleLab.text = self.title;
        self.titleLab.font = [UIFont systemFontOfSize:15];
        self.titleLab.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLab];
        topToContainView = 25;
    }
    
    if (!self.xMarkTitles) {
        
        self.xMarkTitles = @[@0,@1,@2,@3,@4,@5];
    }
    if (![self.yValues.allKeys containsObject:lineID]) {
        [self.yValues setObject:@[@0,@1,@2,@3,@4,@5] forKey:lineID];
    }
    
    
    if (!self.yMarkTitles) {
        self.yMarkTitles = @[@0,@1,@2,@3,@4,@5];
    }
    
    
    if (self.maxValue == 0) {
        self.maxValue = 5;
    }
    if (!_lineGraphContentView) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, topToContainView, self.frame.size.width,self.frame.size.height - topToContainView)];
        [self.scrollView setShowsHorizontalScrollIndicator:NO];
        [self.scrollView setShowsVerticalScrollIndicator:NO];
        [self addSubview:self.scrollView];
        
        self.lineGraphContentView = [[FBYLineGraphContentView alloc] initWithFrame:self.scrollView.bounds];
        
        self.lineGraphContentView.yMarkTitles = _yMarkTitles;
        self.lineGraphContentView.xMarkTitles = _xMarkTitles;
        self.lineGraphContentView.xScaleMarkLEN = _xScaleMarkLEN;
        self.lineGraphContentView.yValues = _yValues;
        self.lineGraphContentView.maxYValue = _maxValue;
        [self.scrollView addSubview:self.lineGraphContentView];
        self.scrollView.contentSize = self.lineGraphContentView.bounds.size;
    }
    [self.lineGraphContentView mappingWithLineId:lineID lineColor:color];
    
    
}

#pragma mark 更新数据
- (void)reloadDatasWithLineId:(NSString *)lineID {
//    dispatch_barrier_async(dispatch_get_global_queue(0, 0), ^{
        if (self.lineGraphContentView) {
            self.lineGraphContentView.yValues = _yValues;
            if ([_yValues.allKeys containsObject:lineID]) {
                NSArray* yValue = _yValues[lineID];
                 self.scrollView.contentSize =CGSizeMake(_xScaleMarkLEN * yValue.count + 20, self.lineGraphContentView.bounds.size.height);
            }
        }
        [self.lineGraphContentView reloadDatasWithLineId:lineID];
//    });
   
}
-(void)closeView{
    [_lineGraphContentView closeView];
    [_lineGraphContentView removeFromSuperview];
    _lineGraphContentView = nil;
}
-(void)dealloc{
    NSLog(@"hosten FBYLineGraphView -----dealloc");
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
