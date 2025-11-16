#!/bin/bash

# Docker Buildx 多平台构建脚本
# 支持构建多个架构的 Docker 镜像

set -e

# 默认镜像名称和标签
IMAGE_NAME="${IMAGE_NAME:-3x-ui}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# 默认构建平台（可以根据需要修改）
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64,linux/arm/v7}"

# 是否推送到仓库（默认不推送，仅构建）
PUSH="${PUSH:-false}"

# 检查是否已安装 buildx
if ! docker buildx version &> /dev/null; then
    echo "错误: docker buildx 未安装或未启用"
    echo "请运行: docker buildx install"
    exit 1
fi

# 创建并使用 buildx builder（如果不存在）
BUILDER_NAME="multiarch-builder"
if ! docker buildx inspect $BUILDER_NAME &> /dev/null; then
    echo "创建新的 buildx builder: $BUILDER_NAME"
    docker buildx create --name $BUILDER_NAME --use --bootstrap
else
    echo "使用现有的 buildx builder: $BUILDER_NAME"
    docker buildx use $BUILDER_NAME
fi

# 构建参数
BUILD_ARGS=""
if [ -n "$IMAGE_NAME" ]; then
    BUILD_ARGS="$BUILD_ARGS --tag $IMAGE_NAME:$IMAGE_TAG"
fi

# 如果设置了仓库地址，添加完整标签
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    BUILD_ARGS="$BUILD_ARGS --tag $FULL_IMAGE_NAME"
    echo "完整镜像名称: $FULL_IMAGE_NAME"
fi

# 构建命令
BUILD_CMD="docker buildx build \
    --platform $PLATFORMS \
    $BUILD_ARGS \
    --file Dockerfile"

# 根据 PUSH 参数决定是构建并推送还是仅构建
if [ "$PUSH" = "true" ]; then
    echo "开始构建并推送多平台镜像..."
    echo "平台: $PLATFORMS"
    $BUILD_CMD --push .
else
    echo "开始构建多平台镜像（仅本地，不推送）..."
    echo "平台: $PLATFORMS"
    $BUILD_CMD --load .
    echo ""
    echo "注意: --load 选项只能加载单个平台镜像到本地"
    echo "如需同时构建多个平台，请使用 --push 推送到仓库，或使用 --output 导出"
fi

echo "构建完成！"

