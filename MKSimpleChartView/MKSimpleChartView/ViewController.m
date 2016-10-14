//
//  ViewController.m
//  MKSimpleChartView
//
//  Created by gkoudai_xsm on 16/10/14.
//  Copyright © 2016年 gkoudai_xsm. All rights reserved.
//

#import "ViewController.h"
#import "MKSimpleChartView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *file = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"];
    NSArray *dataArray = [NSArray arrayWithContentsOfFile:file];
    
    MKSimpleChartView *chartView = [[MKSimpleChartView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)];
    [chartView strokeLineWithChartData:dataArray];
    [self.view addSubview:chartView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
