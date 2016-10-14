//
//  GKDETFChartView.h
//  sojex
//
//  Created by gkoudai_xsm on 16/10/14.
//  Copyright © 2016年 finance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MKSimpleChartView : UIView

/**
 *  数据入口
 *
 *  @param chartData 数据
 */
- (void)strokeLineWithChartData:(NSArray *)chartData;

@end
