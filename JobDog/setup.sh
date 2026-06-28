#!/bin/bash
# Job Dog - Xcode 工程生成脚本
# 在 Mac 终端运行此脚本生成 .xcodeproj

set -e
cd "$(dirname "$0")"

echo "🐕 Job Dog 工程生成器"
echo "===================="

# 检查 xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo ""
    echo "❌ 未检测到 xcodegen"
    echo ""
    echo "安装方式（二选一）："
    echo "  1. brew install xcodegen"
    echo "  2. 手动创建 Xcode 工程（见下方说明）"
    echo ""
    echo "=== 手动创建方式 ==="
    echo "1. 打开 Xcode → File → New → Project"
    echo "2. 选择 iOS → App"
    echo "3. Product Name: JobDog"
    echo "4. Interface: SwiftUI, Language: Swift"
    echo "5. 删除自动生成的 ContentView.swift 和 JobDogApp.swift"
    echo "6. 将 Sources/ 文件夹拖入工程（勾选 Copy items if needed）"
    echo "7. 确保 Info.plist 已配置（工程设置 → Info → Custom iOS Target Properties）"
    echo "8. Cmd+R 运行"
    echo ""
    exit 1
fi

echo "✅ 检测到 xcodegen"
echo "🔨 生成 Xcode 工程..."

xcodegen generate

echo ""
echo "✅ 生成完成！"
echo "📂 打开方式：open JobDog.xcodeproj"
echo ""
echo "或直接双击 JobDog.xcodeproj"
