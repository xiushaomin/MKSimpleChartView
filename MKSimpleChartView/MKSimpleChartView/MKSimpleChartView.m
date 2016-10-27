#import "MKSimpleChartView.h"
#import "UIView+FrameCategory.h"

CGFloat const kGKDFONTSIZE = 9;

@interface MKSimpleChartView()
{
    CGFloat _margin;
    CGFloat _rightMargin;
    CGFloat _maxValue;
    CGFloat _minValue;
    //    CGPoint _pressPoint;
}
@property (nonatomic, strong) NSMutableArray *chartData;
@property (nonatomic, strong) NSMutableArray *chartPointArray;
@property (nonatomic, strong) NSMutableArray *timeLayerArray;
@property (nonatomic, strong) NSMutableArray *valueLayerArray;
@property (nonatomic, strong) NSMutableArray *timeAndValuesArray;
@property (nonatomic, strong) CAShapeLayer *chartLineLayer;
@property (nonatomic, strong) CAShapeLayer *shadowLayer;
@property (nonatomic, strong) CAShapeLayer *frameLayer;
@property (nonatomic, strong) CAShapeLayer *crossLayer;

@end

@implementation MKSimpleChartView

#pragma mark - Initialize

- (instancetype)init {
    if (self = [super init]) {
        [self p_configInitializeValue];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_configInitializeValue];
    }
    return self;
}

- (void)p_configInitializeValue {
    _margin = 10;
    _rightMargin = 10;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPress];
    self.chartData = @[].mutableCopy;
    self.chartPointArray = @[].mutableCopy;
    self.timeLayerArray = @[].mutableCopy;
    self.valueLayerArray = @[].mutableCopy;
    self.timeAndValuesArray = @[].mutableCopy;
    
    self.chartLineLayer = [CAShapeLayer layer];
    self.chartLineLayer.strokeColor = [UIColor colorWithRed:45/255. green:113/255. blue:174/255. alpha:1.].CGColor;
    self.chartLineLayer.fillColor = [UIColor clearColor].CGColor;
    self.chartLineLayer.lineWidth = 1.f;
    [self.layer addSublayer:self.chartLineLayer];
    
    self.frameLayer = [CAShapeLayer layer];
    self.frameLayer.strokeColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.5f].CGColor;
    self.frameLayer.fillColor = [UIColor clearColor].CGColor;
    self.frameLayer.lineWidth = (1.f / [UIScreen mainScreen].scale);
    // self.frameLayer.lineDashPattern = @[@(2),@(2)];
    [self.layer addSublayer:self.frameLayer];
    
    self.shadowLayer = [CAShapeLayer layer];
    self.shadowLayer.strokeColor = [UIColor clearColor].CGColor;
    self.shadowLayer.fillColor = [UIColor colorWithRed:45/255. green:113/255. blue:174/255. alpha:.2f].CGColor;
    [self.layer addSublayer:self.shadowLayer];
    
    self.crossLayer = [CAShapeLayer layer];
    self.crossLayer.strokeColor = [UIColor redColor].CGColor;
    self.crossLayer.fillColor = [UIColor clearColor].CGColor;
    self.crossLayer.lineDashPattern = @[@(2),@(2)];
    [self.layer addSublayer:self.crossLayer];
    
}

#pragma mark - PublicMethods.

- (void)strokeLineWithChartData:(NSArray *)chartData {
    [self p_cleanAllData];
    self.chartData = chartData.mutableCopy;
    [self p_setMaxAndMinValue:self.p_getStrokelist];
    [self p_strokeFramelayers];
    [self p_strokeChartLine];
    [self p_strokeTimeTextLayers];
    [self p_strokeValueTextLayers];
}

#pragma mark - PrivateMethods

- (void)p_cleanAllData {
    [self.chartData removeAllObjects];
    [self.chartPointArray removeAllObjects];
    
    [self.timeLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.timeLayerArray removeAllObjects];
    
    [self.valueLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.valueLayerArray removeAllObjects];
    
    [self.timeAndValuesArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.timeAndValuesArray removeAllObjects];
    
    self.shadowLayer.path = nil;
    self.chartLineLayer.path = nil;
    self.frameLayer.path = nil;
    self.crossLayer.path = nil;
}

- (void)p_setMaxAndMinValue:(NSArray *)list {
    CGFloat maxValue = 0;
    CGFloat minValue = MAXFLOAT;
    for (NSDictionary *dic in list) {
        CGFloat pointValue = [dic[@"p"] floatValue];
        if (pointValue > maxValue) {
            maxValue = pointValue;
        }
        if (pointValue < minValue) {
            minValue = pointValue;
        }
    }
    CGFloat different = maxValue - minValue;
    if (different == 0) {
        different = maxValue * 0.1;
    }
    different *= 0.05;
    maxValue = maxValue + different;
    minValue = minValue - different;
    
    //取目前最大值最小值的余数
    double maxYu = fmodf(maxValue, 10.f);
    double minYu = fmodf(minValue, 10.f);
    //判断余数是否取下一介 也就是取 10 / 0
    int maxTen = [self p_roundToNextSignificant:maxYu];
    int minTen = [self p_roundToNextSignificant:minYu];
    //减去余数 + 加上这个值  也就是个位不管怎么样都为0
    _maxValue = (maxValue - maxYu) + maxTen;
    _minValue = (minValue - minYu) + minTen;
    
    if (_minValue < 0) {
        _minValue = 0;
    }
}


- (void)p_strokeFramelayers {
    CGFloat nStepy = (self.height - 4 * _margin) / 4.f;
    float num = self.p_getStrokelist.count / 4.f;
    int subNum = floor(num);
    CGFloat subX = (self.width - _margin - _rightMargin) / (self.p_getStrokelist.count - 1);
    
    UIBezierPath *frameX_Path = [UIBezierPath bezierPath];
    for (int i = subNum; i < self.p_getStrokelist.count - subNum; i += subNum) {
        [frameX_Path moveToPoint:(CGPoint){subX * i + _margin, _margin}];
        [frameX_Path addLineToPoint:(CGPoint){subX * i + _margin, self.height - _margin}];
    }
    UIBezierPath *frameY_Path = [UIBezierPath bezierPath];
    for (int j = 0; j < 5; ++j) {
        [frameY_Path moveToPoint:(CGPoint){_margin, nStepy * j + 2*_margin}];
        [frameY_Path addLineToPoint:(CGPoint){self.width - _rightMargin, nStepy * j + 2*_margin}];
    }
    
    UIBezierPath *framePath = [UIBezierPath bezierPath];
    [framePath moveToPoint:(CGPoint){_margin, _margin}];
    [framePath addLineToPoint:(CGPoint){self.width - _rightMargin, _margin}];
    [framePath addLineToPoint:(CGPoint){self.width - _rightMargin, self.height - _margin}];
    [framePath addLineToPoint:(CGPoint){_margin, self.height - _margin}];
    [framePath closePath];
    
    [framePath appendPath:frameX_Path];
    [framePath appendPath:frameY_Path];
    self.frameLayer.path = framePath.CGPath;
}


- (void)p_strokeChartLine {
    if (self.p_getStrokelist.count == 0) { return; }
    
    [self.chartPointArray removeAllObjects];
    
    CGFloat subX = (self.width - _margin - _rightMargin) / (self.p_getStrokelist.count - 1);
    CGFloat nY = self.height - 4 * _margin;
    UIBezierPath *chartPath = [UIBezierPath bezierPath];
    NSUInteger i = 0;
    for (NSDictionary *dic in self.p_getStrokelist) {
        CGFloat point = [dic[@"p"] floatValue];
        CGFloat y = (_maxValue - point) / (_maxValue - _minValue) * nY + _margin * 2;
        CGFloat x = _margin + i * subX;
        if (i == 0) {
            [chartPath moveToPoint:(CGPoint){x, y}];
        } else {
            [chartPath addLineToPoint:(CGPoint){x, y}];
        }
        NSValue *pointValue = [NSValue valueWithCGPoint:(CGPoint){x, y}];
        [self.chartPointArray addObject:pointValue];
        i++;
    }
    self.chartLineLayer.path = chartPath.CGPath;
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithCGPath:chartPath.CGPath];
    [shadowPath addLineToPoint:(CGPoint){self.width - _rightMargin, self.height - _margin}];
    [shadowPath addLineToPoint:(CGPoint){_margin, self.height - _margin}];
    [shadowPath closePath];
    
    self.shadowLayer.path = shadowPath.CGPath;
}

- (void)p_strokeTimeTextLayers {
    UIFont *font = [UIFont systemFontOfSize:kGKDFONTSIZE];
    CFStringRef fontName = (__bridge CFStringRef)(font.fontName);
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    
    [self.timeLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.timeLayerArray removeAllObjects];
    
    float num = self.p_getStrokelist.count / 4.f;
    int subNum = floor(num);
    //  int step = 1;
    CGFloat subX = (self.width - _margin - _rightMargin) / (self.p_getStrokelist.count - 1);
    //  CGFloat nStepx = (self.width - _margin - _rightMargin) / 4.f;
    
    for (int i = subNum; i < self.p_getStrokelist.count - subNum; i+=subNum) {
        CATextLayer *timeTextLayer = [CATextLayer layer];
        timeTextLayer.font = fontRef;
        timeTextLayer.fontSize = font.pointSize;
        timeTextLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
        timeTextLayer.contentsScale = [UIScreen mainScreen].scale;
        NSString *timeStr = self.p_getStrokelist[i][@"t"];
        timeTextLayer.string = timeStr;
        CGSize timeSize = [timeStr sizeWithAttributes:@{NSFontAttributeName:font}];
        timeTextLayer.frame = (CGRect){subX * i + _margin - timeSize.width / 2, self.height - _margin,timeSize};
        [self.layer addSublayer:timeTextLayer];
        [self.timeLayerArray addObject:timeTextLayer];
    }
    CFRelease(fontRef);
}


- (void)p_strokeValueTextLayers {
    UIFont *font = [UIFont systemFontOfSize:kGKDFONTSIZE];
    CFStringRef fontNameRef = (__bridge CFStringRef)(font.fontName);
    CGFontRef fontRef = CGFontCreateWithFontName(fontNameRef);
    
    [self.valueLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.valueLayerArray removeAllObjects];
    
    float subValue = (_maxValue - _minValue)/4.f;
    CGFloat nStepy = (self.height - 4 * _margin) / 4.f;
    
    for (int i = 0; i < 5; ++i) {
        CATextLayer *valueLayer = [CATextLayer layer];
        valueLayer.font = fontRef;
        valueLayer.fontSize = font.pointSize;
        valueLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
        valueLayer.contentsScale = [UIScreen mainScreen].scale;
        NSString *valueString = [NSString stringWithFormat:@"%.1f",_maxValue - i*subValue];
        valueLayer.string = valueString;
        CGSize valueSize = [valueString sizeWithAttributes:@{NSFontAttributeName : font}];
        valueLayer.frame = (CGRect){self.width - _rightMargin - valueSize.width, nStepy * i + 2*_margin - valueSize.height/2, valueSize};
        [self.layer addSublayer:valueLayer];
        [self.valueLayerArray addObject:valueLayer];
    }
    CFRelease(fontRef);
}

#pragma mark - longPress

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];
            [self p_showCrossLayerWith:point];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self p_showCrossLayerWith:CGPointZero];
            break;
        default:
            
            break;
    }
}

- (void)p_showCrossLayerWith:(CGPoint)pressPoint {
    [self.timeAndValuesArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.timeAndValuesArray removeAllObjects];
    if (CGPointEqualToPoint(pressPoint, CGPointZero)) {
        self.crossLayer.path = nil;
        return;
    }
    CGFloat subX = (self.width - _margin - _rightMargin) / (self.p_getStrokelist.count - 1);
    CGFloat nY = self.height - 4 * _margin;
    NSUInteger i = 0;
    CGFloat minPadding = 0.f;
    CGPoint crossPoint;
    NSDictionary *dataDic;
    for (NSDictionary *dic in self.p_getStrokelist) {
        CGFloat pointValue = [dic[@"p"] floatValue];
        CGFloat y = (_maxValue - pointValue) / (_maxValue - _minValue) * nY + 2 * _margin;
        CGFloat x = _margin + i * subX;
        CGPoint point = (CGPoint){x, y};
        if (i == 0) {
            minPadding = fabs(point.x - pressPoint.x);
            crossPoint = point;
            dataDic = dic;
        }
        if (fabs(point.x - pressPoint.x) < minPadding) {
            minPadding = fabs(point.x - pressPoint.x);
            crossPoint = point;
            dataDic = dic;
        }
        i++;
    }
    UIBezierPath *x_crossPath = [UIBezierPath bezierPath];
    [x_crossPath moveToPoint:(CGPoint){crossPoint.x, self.height - _margin}];
    [x_crossPath addLineToPoint:(CGPoint){crossPoint.x, _margin}];
    UIBezierPath *y_crossPath = [UIBezierPath bezierPath];
    [y_crossPath moveToPoint:(CGPoint){_margin, crossPoint.y}];
    [y_crossPath addLineToPoint:(CGPoint){self.width - _rightMargin, crossPoint.y}];
    [x_crossPath appendPath:y_crossPath];
    self.crossLayer.path = x_crossPath.CGPath;
    
    [self p_strokeTimesAndValuesTextLayersAtCrossPoint:crossPoint WithDataDic:dataDic];
}

- (void)p_strokeTimesAndValuesTextLayersAtCrossPoint:(CGPoint)crossPoint WithDataDic:(NSDictionary *)dataDic {
    
    UIFont *font = [UIFont systemFontOfSize:9.0];
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    
    CATextLayer *timeTextLayer = [CATextLayer new];
    timeTextLayer.font = fontRef;
    timeTextLayer.fontSize = font.pointSize;
    timeTextLayer.foregroundColor = [UIColor whiteColor].CGColor;
    timeTextLayer.backgroundColor = [UIColor colorWithRed:145.0 / 255.0 green:150.0 / 255.0 blue:155.0 / 255.0 alpha:230.0 / 255.0].CGColor;
    timeTextLayer.contentsScale = [UIScreen mainScreen].scale;
    NSString *timeString = dataDic[@"t"];
    timeTextLayer.string = timeString;
    CGSize t_size = [timeTextLayer.string sizeWithAttributes:@{NSFontAttributeName:font}];
    CGFloat x = crossPoint.x - t_size.width / 2;
    if (x > self.width - _margin - t_size.width) {
        x = self.width - _margin - t_size.width;
    }
    if (x < _margin) {
        x = _margin;
    }
    timeTextLayer.frame = (CGRect){x, self.height - _margin - t_size.height, t_size};
    
    CATextLayer *valueTextLayer = [CATextLayer new];
    valueTextLayer.font = fontRef;
    valueTextLayer.fontSize = font.pointSize;
    valueTextLayer.foregroundColor = [UIColor whiteColor].CGColor;
    valueTextLayer.backgroundColor = [UIColor colorWithRed:145.0 / 255.0 green:150.0 / 255.0 blue:155.0 / 255.0 alpha:230.0 / 255.0].CGColor;
    valueTextLayer.contentsScale = [UIScreen mainScreen].scale;
    valueTextLayer.string = dataDic[@"p"];
    CGSize v_size = [valueTextLayer.string sizeWithAttributes:@{NSFontAttributeName:font}];
    valueTextLayer.frame = (CGRect){_margin, crossPoint.y - v_size.height / 2, v_size};
    [self.layer addSublayer:timeTextLayer];
    [self.layer addSublayer:valueTextLayer];
    
    [self.timeAndValuesArray addObject:timeTextLayer];
    [self.timeAndValuesArray addObject:valueTextLayer];
    
    CFRelease(fontRef);
}


#pragma mark - 暂时弃用
- (float)p_roundToNextSignificant:(double)number {
    // 先取log10的对数
    // 例如: num = 900  log10（900）= 2.9542425094393248;
    // d = 3;
    // pw = -3;
    // magnitude = 10^(-3)
    // shiffted = round(0.9) = 1;
    // return = 1/10^(-3)
    // 是否取下一级数。。
    float d = ceil(log10(number < 0 ? -number : number));
    if (d > 0) { ++d; }
    int pw = 1 - (int)d;
    float magnitude = pow(10, pw);
    long shifted = round(number * magnitude);
    return shifted / magnitude;
}

- (NSArray *)p_getStrokelist{
    if (self.chartData.count > 0) {
        NSDictionary *dataDic = [self.chartData firstObject];
        NSArray *list = dataDic[@"list"];
        if (list) { return list; } else { return nil; }
    } else { return nil; }
}

@end
