# HPM RISC-V 项目构建 Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xianii/hpm-dev-docker)](https://hub.docker.com/r/xianii/hpm-dev-docker)
[![Docker Image Version](https://img.shields.io/docker/v/xianii/hpm-dev-docker?sort=semver)](https://hub.docker.com/r/xianii/hpm-dev-docker)

一个面向 HPM 系列 RISC-V MCU 项目的命令行交叉编译环境，包含 xPack `riscv-none-elf` GCC 13.2.0-2、CMake 和 Ninja。源码与 HPM SDK 由使用者提供，容器不绑定特定应用或 HPM-gateway 仓库。

## 拉取镜像

```sh
docker pull xianii/hpm-dev-docker:latest
```

也可使用发布版本标签，例如 `v1.0.0`。

## 编译 HPM 工程

准备一个 HPM RISC-V 工程目录和与该工程匹配的 HPM SDK。以下示例将工程挂载到 `/src`、SDK 只读挂载到 `/sdk`，并将构建目录映射到宿主机：

```sh
PROJECT_DIR=/absolute/path/to/your/project
SDK_DIR=/absolute/path/to/your/hpm-sdk
mkdir -p "$PROJECT_DIR/build"

docker run --rm \
  -v "$PROJECT_DIR:/src" \
  -v "$SDK_DIR:/sdk:ro" \
  -v "$PROJECT_DIR/build:/build" \
  -w /src \
  -e HPM_SDK_BASE=/sdk \
  xianii/hpm-dev-docker:latest \
  sh -ec 'cmake -S . -B /build -GNinja \
    -DBOARD=YOUR_HPM_BOARD \
    -DHPM_BUILD_TYPE=flash_xip \
    -DRV_ARCH=YOUR_RISCV_ARCH \
    -DCUSTOM_TARGET_TRIPLET=riscv-none-elf \
    "-DEXCLUDED_IDES=iar;ses" && \
    cmake --build /build --parallel'
```

将 `YOUR_HPM_BOARD`、`YOUR_RISCV_ARCH` 和构建类型替换为芯片、板卡及工程所需的值；工程的 CMake 配置若使用其他 SDK 参数，也应一并传入。构建产物写入宿主机的 `build` 目录，具体文件名和子目录由工程决定。若 SDK 已包含在工程目录中，不必单独挂载 SDK；将 `HPM_SDK_BASE` 设置为容器内该 SDK 的路径即可。

镜像将 `GNURISCV_TOOLCHAIN_PATH` 预设为 `/opt/riscv`，并将工具加入 `PATH`。`HPM_SDK_BASE` 则指向工程匹配的外置 SDK。命令排除 IAR/SES 工程生成，仅用于命令行构建，不需要安装 SES 或 IAR。

## 支持范围

该镜像提供通用的 RISC-V 编译工具入口，但当前 Dockerfile 为缩小体积移除了 xPack 工具链中的其他 `rv*` multilib；镜像目前只针对 HPM6E80 的 RV32IMAC 工程验证通过（`rv32imac_zicsr_zifencei`）。其他 HPM 芯片/ISA 需要确认 SDK、`RV_ARCH` 与链接所需运行库均匹配；如遇缺少 multilib 或链接库错误，应使用包含对应 multilib 的工具链，并相应调整 Dockerfile 的裁剪步骤后重新构建镜像。

## 自行构建镜像

在本目录执行：

```sh
docker build -t xianii/hpm-dev-docker:local .
```

之后将编译命令中的 `xianii/hpm-dev-docker:latest` 替换为 `xianii/hpm-dev-docker:local`。Dockerfile 固定使用 xPack RISC-V GCC 13.2.0-2。

## 自动发布到 Docker Hub

GitHub Actions 在默认分支推送或推送 `v*` 标签时构建并发布镜像；Pull Request 只构建验证，不推送镜像。GitHub 仓库 `Nigh/hpm-dev-docker` 需设置以下 Actions secrets：

- `DOCKERHUB_USERNAME`：Docker Hub 用户名。
- `DOCKERHUB_TOKEN`：Docker Hub access token。

不要将 Docker Hub token 写入仓库或提交到 Git。镜像发布地址为 `xianii/hpm-dev-docker`。
