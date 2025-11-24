//
//  DataCPlus.cpp
//  Runner
//
//  Created by LJ on 2025/11/24.
//

#include "DataCPlus.hpp"
#include <sstream>
#include <iomanip>
#include <ctime>
#include <chrono>
#include <random>
#include <algorithm>
#include <numeric>

// 构造函数
DataCPlus::DataCPlus() {
    // 初始化随机数生成器
    srand(static_cast<unsigned>(time(nullptr)));
}

// 析构函数
DataCPlus::~DataCPlus() {
}

// 生成模拟数据
std::string DataCPlus::generateSimulationData() {
    std::ostringstream oss;
    
    // 构建 JSON 格式的数据
    oss << "{"
        << "\"timestamp\":" << getCurrentTimestamp() << ","
        << "\"randomString\":\"" << generateRandomString(10) << "\","
        << "\"randomNumber\":" << (rand() % 1000) << ","
        << "\"status\":\"successadd\","
        << "\"source\":\"CPlusPlusadd\""
        << "}";
    
    return oss.str();
}

// 处理字符串数据（模拟简单加密）
std::string DataCPlus::processString(const std::string& input) {
    std::string result = input;
    
    // 简单的字符偏移加密（Caesar cipher）
    for (size_t i = 0; i < result.length(); i++) {
        if (result[i] >= 'a' && result[i] <= 'z') {
            result[i] = ((result[i] - 'a' + 3) % 26) + 'a';
        } else if (result[i] >= 'A' && result[i] <= 'Z') {
            result[i] = ((result[i] - 'A' + 3) % 26) + 'A';
        }
    }
    
    return result;
}

// 计算数据统计信息
std::map<std::string, double> DataCPlus::calculateStatistics(const std::vector<int>& numbers) {
    std::map<std::string, double> stats;
    
    if (numbers.empty()) {
        stats["average"] = 0.0;
        stats["max"] = 0.0;
        stats["min"] = 0.0;
        stats["sum"] = 0.0;
        return stats;
    }
    
    // 计算总和
    int sum = std::accumulate(numbers.begin(), numbers.end(), 0);
    
    // 计算平均值
    double average = static_cast<double>(sum) / numbers.size();
    
    // 查找最大值和最小值
    int maxVal = *std::max_element(numbers.begin(), numbers.end());
    int minVal = *std::min_element(numbers.begin(), numbers.end());
    
    stats["average"] = average;
    stats["max"] = static_cast<double>(maxVal);
    stats["min"] = static_cast<double>(minVal);
    stats["sum"] = static_cast<double>(sum);
    stats["count"] = static_cast<double>(numbers.size());
    
    return stats;
}

// 模拟复杂数据传输
std::string DataCPlus::simulateDataTransfer(int userId, int messageCount) {
    std::ostringstream oss;
    
    // 构建复杂的 JSON 数据
    oss << "{"
        << "\"userId\":" << userId << ","
        << "\"messageCount\":" << messageCount << ","
        << "\"timestamp\":" << getCurrentTimestamp() << ","
        << "\"messages\":[";
    
    // 生成模拟消息列表
    for (int i = 0; i < messageCount; i++) {
        if (i > 0) oss << ",";
        oss << "{"
            << "\"id\":" << (i + 1) << ","
            << "\"content\":\"" << generateRandomString(20) << "\","
            << "\"timestamp\":" << (getCurrentTimestamp() - (messageCount - i) * 1000)
            << "}";
    }
    
    oss << "],"
        << "\"status\":\"completed\","
        << "\"dataSource\":\"CPlusPlus\","
        << "\"processedBy\":\"DataCPlus::simulateDataTransfer\""
        << "}";
    
    return oss.str();
}

// 生成随机字符串
std::string DataCPlus::generateRandomString(int length) {
    const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const size_t max_index = sizeof(charset) - 1;
    
    std::string result;
    result.reserve(length);
    
    for (int i = 0; i < length; i++) {
        result += charset[rand() % max_index];
    }
    
    return result;
}

// 获取当前时间戳（毫秒）
long long DataCPlus::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto duration = now.time_since_epoch();
    auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
    return millis;
}
