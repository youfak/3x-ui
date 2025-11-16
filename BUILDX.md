# Docker Buildx 多平台构建指南

## 问题解决

如果遇到错误：
```
ERROR: failed to build: Multi-platform build is not supported for the docker driver.
```

这是因为默认的 docker driver 不支持多平台构建。需要创建使用 `docker-container` driver 的 builder。

## 快速设置

### 方法 1: 使用设置脚本（推荐）

```bash
chmod +x setup-buildx.sh
./setup-buildx.sh
```

### 方法 2: 手动设置

```bash
# 创建支持多平台的 builder
docker buildx create --name multiarch-builder --driver docker-container --use

# 启动 builder
docker buildx inspect --bootstrap

# 验证设置
docker buildx ls
```

## 使用方法

### 使用构建脚本

```bash
# 设置环境变量（可选）
export IMAGE_NAME="youfak/3x-ui"
export IMAGE_TAG="latest"
export PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
export PUSH="true"

# 运行构建脚本
chmod +x buildx-build.sh
./buildx-build.sh
```

### 直接使用 docker buildx 命令

```bash
# 确保使用正确的 builder
docker buildx use multiarch-builder

# 构建并推送多平台镜像
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t youfak/3x-ui:latest \
  --push \
  .
```

### 仅构建不推送（用于测试）

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t youfak/3x-ui:latest \
  --load \
  .
```

注意：`--load` 只能加载单个平台到本地。多平台构建必须使用 `--push` 推送到仓库。

## 支持的平台

- `linux/amd64` - 64位 x86
- `linux/arm64` - 64位 ARM
- `linux/arm/v7` - 32位 ARM v7
- `linux/arm/v6` - 32位 ARM v6

## 验证构建结果

构建完成后，可以在 Docker Hub 或其他镜像仓库中查看多平台镜像的 manifest：

```bash
docker buildx imagetools inspect youfak/3x-ui:latest
```

## 常见问题

### Q: 如何删除现有的 builder？

```bash
docker buildx rm multiarch-builder
```

### Q: 如何查看所有可用的 builder？

```bash
docker buildx ls
```

### Q: 构建速度慢怎么办？

多平台构建需要为每个平台分别构建，这是正常的。可以考虑：
1. 只构建需要的平台
2. 使用 GitHub Actions 或其他 CI/CD 进行构建
3. 使用本地缓存：`--cache-from` 和 `--cache-to`

