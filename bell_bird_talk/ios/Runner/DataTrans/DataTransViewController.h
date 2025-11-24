//
//  DataTransViewController.h
//  Runner
//
//  Created by LJ on 2025/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// iOS 原生 ViewController，负责调用 C++ 代码并处理数据
@interface DataTransViewController : UIViewController

/// 从 C++ 生成模拟数据
+ (NSString *)generateSimulationDataFromCPP;

/// 处理字符串（调用 C++ 加密方法）
+ (NSString *)processStringWithCPP:(NSString *)input;

/// 计算统计数据（调用 C++ 计算方法）
+ (NSDictionary *)calculateStatisticsWithCPP:(NSArray<NSNumber *> *)numbers;

/// 模拟数据传输（从 C++ 获取复杂结构化数据）
+ (NSString *)simulateDataTransferWithCPP:(NSInteger)userId messageCount:(NSInteger)messageCount;

@end

NS_ASSUME_NONNULL_END
