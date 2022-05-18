//
//  FBYLineGraphContentView.m
//  FBYDataDisplay-iOS
//
//  Created by fby on 2018/1/18.
//  Copyright © 2018年 FBYDataDisplay-iOS. All rights reserved.
//

#import "FBYLineGraphContentView.h"

#import "FBYLineGraphColorView.h"

// Tag 基初值
#define BASE_TAG_COVERVIEW 100
#define BASE_TAG_CIRCLEVIEW 200
#define BASE_TAG_POPBTN 300
@interface FBYLineGraphContentView()
@property(nonatomic,assign)BOOL isFirst;
@property(nonatomic,strong)UIView *contentView;
@property(nonatomic,strong)NSMutableDictionary<NSString*,CAShapeLayer*> *bezierPaths;
@property(nonatomic,strong)NSMutableDictionary<NSString*,UIColor*> *lineColor;
@end
@interface FBYLineGraphContentView() {
    
    NSMutableArray *pointArray;
    NSMutableArray *pointRedArray;
    NSInteger lastSelectedIndex;
}

@end

@implementation FBYLineGraphContentView
-(NSMutableDictionary<NSString *,CAShapeLayer *> *)bezierPaths{
    if (!_bezierPaths) {
        _bezierPaths = [[NSMutableDictionary alloc] init];
    }
    return _bezierPaths;
}


//- (void)setValueArray:(NSArray *)valueArray {
//    _valueArray = valueArray;
//}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        lastSelectedIndex = - 1;
        pointArray = [NSMutableArray array];
        pointRedArray = [NSMutableArray array];
        self.yAxis_L = frame.size.height;
        self.xAxis_L = frame.size.width;
        self.contentView = [[UIView alloc]initWithFrame:frame];
        [self addSubview:self.contentView];
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    return  self;
}

- (void)mappingWithLineId:(NSString *)lineID lineColor:(UIColor *)color{
    if (!_isFirst) {//外面的框值绘制一次
        [super mappingWithLineId:lineID lineColor:color];
        _isFirst = YES;
        _lineColor = [NSMutableDictionary dictionary];
    }
    if (color) {
        if (![_lineColor.allKeys containsObject:lineID]) {
            [_lineColor setObject:color forKey:lineID];
        }
    }
    
    [self drawChartLineWithYValue:_yValues[lineID] lineId:lineID];
//    [self drawChartLineTwoWithYValue:_yValues[lineID]];
//    [self drawGradient];//取消阴影效果
    
//    [self setupCircleViews];//取消圆点效果
//    [self setupCoverViews];//取消点击图层效果
}

- (void)reloadDatasWithLineId:(NSString *)lineID{
    
//    [super reloadDatasWithLineId:lineID];
    
    [self clearViewWithID:lineID];
    [self mappingWithLineId:lineID lineColor:nil];
}

#pragma mark 画折线图
- (void)drawChartLineWithYValue:(NSArray*)valueArray lineId:(NSString*)lineID{
    UIBezierPath *pAxisPath = [[UIBezierPath alloc] init];
    
    for (int i = 0; i < valueArray.count; i ++) {
        
        CGFloat point_X = self.xScaleMarkLEN * i + self.startPoint.x;
        
        CGFloat value = [valueArray[i] floatValue];
        CGFloat percent = value / self.maxYValue;
        CGFloat point_Y = self.yAxis_L * (1 - percent) + self.startPoint.y;
        
        CGPoint point = CGPointMake(point_X, point_Y);
        
        // 记录各点的坐标方便后边添加渐变阴影 和 点击层视图 等
        [pointArray addObject:[NSValue valueWithCGPoint:point]];
        
        if (i == 0) {
            [pAxisPath moveToPoint:point];
        }else {
            [pAxisPath addLineToPoint:point];
        }
    }
    
    CAShapeLayer *pAxisLayer = [CAShapeLayer layer];
    pAxisLayer.lineWidth = 1;
    pAxisLayer.fillColor = [UIColor clearColor].CGColor;
    pAxisLayer.path = pAxisPath.CGPath;
    pAxisLayer.strokeColor = _lineColor[lineID].CGColor;
    [self.contentView.layer addSublayer:pAxisLayer];
    [self.bezierPaths setObject:pAxisLayer forKey:lineID];
    
}
#pragma mark 渐变阴影
- (void)drawGradient {
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//    gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:250/255.0 green:170/255.0 blue:10/255.0 alpha:0.8].CGColor,(__bridge id)[UIColor colorWithWhite:1 alpha:0.1].CGColor];
    
    gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:0.8].CGColor,(__bridge id)[UIColor colorWithWhite:1 alpha:0.1].CGColor];
    
    gradientLayer.locations=@[@0.0,@1.0];
    gradientLayer.startPoint = CGPointMake(0.0,0.0);
    gradientLayer.endPoint = CGPointMake(0.0,1);
    
    UIBezierPath *gradientPath = [[UIBezierPath alloc] init];
    [gradientPath moveToPoint:CGPointMake(self.startPoint.x, self.yAxis_L + self.startPoint.y)];
    
    for (int i = 0; i < pointArray.count; i ++) {
        [gradientPath addLineToPoint:[pointArray[i] CGPointValue]];
    }
    
    CGPoint endPoint = [[pointArray lastObject] CGPointValue];
    endPoint = CGPointMake(endPoint.x + self.startPoint.x, self.yAxis_L + self.startPoint.y);
    [gradientPath addLineToPoint:endPoint];
    CAShapeLayer *arc = [CAShapeLayer layer];
    arc.path = gradientPath.CGPath;
    gradientLayer.mask = arc;
    [self.contentView.layer addSublayer:gradientLayer];
    
}

#pragma mark 折线上的圆环
- (void)setupCircleViews {
    for (int i = 0; i < pointArray.count; i ++) {
        FBYLineGraphColorView *lineGraphColorView = [[FBYLineGraphColorView alloc] initWithCenter:[pointArray[i] CGPointValue] radius:4];
        lineGraphColorView.tag = i + BASE_TAG_CIRCLEVIEW;
        lineGraphColorView.borderColor = [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1];
        lineGraphColorView.borderWidth = 1.0;
        [self.contentView addSubview:lineGraphColorView];
    }
}

#pragma mark 覆盖一层点击图层
- (void)setupCoverViews {
    
    for (int i = 0; i < pointArray.count; i ++) {
        
        UIView *coverView = [[UIView alloc] init];
        coverView.tag = BASE_TAG_COVERVIEW + i;
        
        if (i == 0) {
            
            coverView.frame = CGRectMake(self.startPoint.x, self.startPoint.y, self.xScaleMarkLEN  / 2, self.yAxis_L);
            [self.contentView addSubview:coverView];
        }
        else if (i == pointArray.count - 1 && pointArray.count == self.xMarkTitles.count) {
            CGPoint point = [pointArray[i] CGPointValue];
            coverView.frame = CGRectMake(point.x - self.xScaleMarkLEN / 2, self.startPoint.y, self.xScaleMarkLEN  / 2, self.yAxis_L);
            [self.contentView addSubview:coverView];
        }
        else {
            CGPoint point = [pointArray[i] CGPointValue];
            coverView.frame = CGRectMake(point.x - self.xScaleMarkLEN / 2, self.startPoint.y, self.xScaleMarkLEN, self.yAxis_L);
            [self.contentView addSubview:coverView];
        }
        UITapGestureRecognizer *gesutre = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gesutreAction:)];
        [coverView addGestureRecognizer:gesutre];
    }
}

#pragma mark- 点击层视图的点击事件
- (void)gesutreAction:(UITapGestureRecognizer *)sender {
    
    NSInteger index = sender.view.tag - BASE_TAG_COVERVIEW;
    
    if (lastSelectedIndex != -1) {
        
        FBYLineGraphColorView *lineGraphColorView = (FBYLineGraphColorView *)[self viewWithTag:lastSelectedIndex + BASE_TAG_CIRCLEVIEW];
        lineGraphColorView.borderWidth = 1;
        
        UIButton *lastPopBtn = (UIButton *)[self viewWithTag:lastSelectedIndex + BASE_TAG_POPBTN];
        [lastPopBtn removeFromSuperview];
    }
    
    FBYLineGraphColorView *lineGraphColorView = (FBYLineGraphColorView *)[self viewWithTag:index + BASE_TAG_CIRCLEVIEW];
    lineGraphColorView.borderWidth = 2;
    
    CGPoint point = [pointArray[index] CGPointValue];
    
    UIButton *popBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    popBtn.tag = index + BASE_TAG_POPBTN;
    popBtn.frame = CGRectMake(point.x - 10, point.y - 20, 20, 15);
    
    [popBtn setBackgroundImage:[UIImage imageNamed:@"bgcolors"] forState:UIControlStateNormal];
    
    [popBtn setTitleEdgeInsets:UIEdgeInsetsMake(- 3, 0, 0, 0)];
    popBtn.titleLabel.font = [UIFont systemFontOfSize:10];
//    [popBtn setTitle:[NSString stringWithFormat:@"%@",self.valueArray[index]] forState:(UIControlStateNormal)];
    
    [self.contentView addSubview:popBtn];
    
    lastSelectedIndex = index;
}

#pragma mark- 清空视图
- (void)clearViewWithID:(NSString*)lineID {
    if (lineID == nil) {
        for ( CAShapeLayer *laye in _bezierPaths.allValues) {
            laye.path = nil;
            [laye removeFromSuperlayer];
        }
        [_bezierPaths removeAllObjects];
    }else{
        if ([_bezierPaths.allKeys containsObject:lineID]) {
            CAShapeLayer *laye = _bezierPaths[lineID];
            laye.path = nil;
            [laye removeFromSuperlayer];
        }
        [_bezierPaths removeObjectForKey:lineID];
    }
   
//    pointArray = [NSMutableArray array];
//    [self removeSubviews];
//    [self removeSublayers];
    
}

#pragma mark 移除 点击图层 、圆环 、数值标签
- (void)removeSubviews {
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
}

#pragma mark 移除折线
- (void)removeSublayers {
    self.contentView.layer.sublayers = nil;
}
-(void)closeView{
    [self clearViewWithID:nil];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)dealloc{
    NSLog(@"hosten FBYLineGraphContentView -----dealloc");
}
@end
