#import <UIKit/UIKit.h>

@interface MKSimpleChartView : UIView

/**
 *  数据入口
 *
 *  @param chartData 数据
 */
- (void)strokeLineWithChartData:(NSArray *)chartData;

@end
