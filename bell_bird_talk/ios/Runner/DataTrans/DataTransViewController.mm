//
//  DataTransViewController.m
//  Runner
//
//  Created by LJ on 2025/11/24.
//

#import "DataTransViewController.h"
#import "DataCPlus.hpp"

@interface DataTransViewController ()

@end

@implementation DataTransViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - C++ 数据传输方法

/// 从 C++ 生成模拟数据
+ (NSString *)generateSimulationDataFromCPP {
    DataCPlus dataCPlus;
    std::string result = dataCPlus.generateSimulationData();
    return [NSString stringWithUTF8String:result.c_str()];
}

/// 处理字符串（调用 C++ 加密方法）
+ (NSString *)processStringWithCPP:(NSString *)input {
    if (!input || input.length == 0) {
        return @"";
    }
    
    DataCPlus dataCPlus;
    std::string cppInput = [input UTF8String];
    std::string result = dataCPlus.processString(cppInput);
    return [NSString stringWithUTF8String:result.c_str()];
}

/// 计算统计数据（调用 C++ 计算方法）
+ (NSDictionary *)calculateStatisticsWithCPP:(NSArray<NSNumber *> *)numbers {
    if (!numbers || numbers.count == 0) {
        return @{};
    }
    
    // 将 NSArray 转换为 std::vector
    std::vector<int> cppNumbers;
    for (NSNumber *num in numbers) {
        cppNumbers.push_back([num intValue]);
    }
    
    // 调用 C++ 方法
    DataCPlus dataCPlus;
    std::map<std::string, double> stats = dataCPlus.calculateStatistics(cppNumbers);
    
    // 将 std::map 转换为 NSDictionary
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (const auto& pair : stats) {
        NSString *key = [NSString stringWithUTF8String:pair.first.c_str()];
        result[key] = @(pair.second);
    }
    
    return [result copy];
}

/// 模拟数据传输（从 C++ 获取复杂结构化数据）
+ (NSString *)simulateDataTransferWithCPP:(NSInteger)userId messageCount:(NSInteger)messageCount {
    DataCPlus dataCPlus;
    std::string result = dataCPlus.simulateDataTransfer((int)userId, (int)messageCount);
    return [NSString stringWithUTF8String:result.c_str()];
}

@end
