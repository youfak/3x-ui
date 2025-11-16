#!/bin/bash

# Docker Buildx 多平台构建环境设置脚本
# 用于创建支持多平台构建的 buildx builder

set -e

BUILDER_NAME="multiarch-builder"

echo "=== Docker Buildx 多平台构建环境设置 ==="
echo ""

# 检查 buildx 是否已安装
if ! docker buildx version &> /dev/null; then
    echo "错误: docker buildx 未安装"
    echo "请先安装 buildx 插件"
    exit 1
fi

echo "1. 检查现有的 builder..."
if docker buildx inspect $BUILDER_NAME &> /dev/null; then
    echo "   Builder '$BUILDER_NAME' 已存在"
    read -p "   是否要删除并重新创建? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   删除现有 builder..."
        docker buildx rm $BUILDER_NAME || true
    else
        echo "   使用现有 builder"
        docker buildx use $BUILDER_NAME
        docker buildx inspect --bootstrap
        echo ""
        echo "设置完成！"
        exit 0
    fi
fi

echo ""
echo "2. 创建新的 builder (使用 docker-container driver)..."
docker buildx create --name $BUILDER_NAME --driver docker-container --use

echo ""
echo "3. 启动 builder..."
docker buildx inspect --bootstrap

echo ""
echo "4. 验证 builder 状态..."
echo "当前使用的 builder:"
docker buildx ls

echo ""
echo "=== 设置完成！ ==="
echo ""
echo "现在可以使用以下命令进行多平台构建:"
echo "  docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t your-image:tag --push ."
echo ""
echo "或使用构建脚本:"
echo "  ./buildx-build.sh"

