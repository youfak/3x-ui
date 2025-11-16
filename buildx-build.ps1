# Docker Buildx 多平台构建脚本 (PowerShell)
# 支持构建多个架构的 Docker 镜像

param(
    [string]$ImageName = "3x-ui",
    [string]$ImageTag = "latest",
    [string]$Platforms = "linux/amd64,linux/arm64,linux/arm/v7",
    [string]$Registry = "",
    [switch]$Push = $false
)

# 检查是否已安装 buildx
try {
    docker buildx version | Out-Null
} catch {
    Write-Host "错误: docker buildx 未安装或未启用" -ForegroundColor Red
    Write-Host "请运行: docker buildx install" -ForegroundColor Yellow
    exit 1
}

# 创建并使用 buildx builder（如果不存在）
$BuilderName = "multiarch-builder"
try {
    docker buildx inspect $BuilderName | Out-Null
    Write-Host "使用现有的 buildx builder: $BuilderName" -ForegroundColor Green
    docker buildx use $BuilderName
} catch {
    Write-Host "创建新的 buildx builder: $BuilderName" -ForegroundColor Green
    docker buildx create --name $BuilderName --use --bootstrap
}

# 构建参数
$BuildArgs = @()
$BuildArgs += "--platform", $Platforms

# 添加标签
if ($Registry) {
    $FullImageName = "$Registry/$ImageName`:$ImageTag"
    $BuildArgs += "--tag", $FullImageName
    Write-Host "完整镜像名称: $FullImageName" -ForegroundColor Cyan
} else {
    $BuildArgs += "--tag", "$ImageName`:$ImageTag"
}

$BuildArgs += "--file", "Dockerfile"

# 根据 Push 参数决定是构建并推送还是仅构建
if ($Push) {
    Write-Host "开始构建并推送多平台镜像..." -ForegroundColor Green
    Write-Host "平台: $Platforms" -ForegroundColor Cyan
    $BuildArgs += "--push", "."
} else {
    Write-Host "开始构建多平台镜像（仅本地，不推送）..." -ForegroundColor Green
    Write-Host "平台: $Platforms" -ForegroundColor Cyan
    $BuildArgs += "--load", "."
    Write-Host ""
    Write-Host "注意: --load 选项只能加载单个平台镜像到本地" -ForegroundColor Yellow
    Write-Host "如需同时构建多个平台，请使用 --push 推送到仓库" -ForegroundColor Yellow
}

# 执行构建
Write-Host "执行命令: docker buildx build $($BuildArgs -join ' ')" -ForegroundColor Gray
docker buildx build @BuildArgs

Write-Host "构建完成！" -ForegroundColor Green

