# HPM slave 编译 Docker

提供 `hj-slave` 的命令行交叉编译环境：xPack RISC-V GCC 13.2.0-2、CMake 和 Ninja。当前镜像按 HPM6E80 的 RV32IMAC 目标裁剪，只保留该目标所需的编译器运行库。

## 拉取镜像

```sh
docker pull xianii/hpm-dev-docker:latest
```

版本标签可替代 `latest`，例如 `v1.0.0`。

## 编译 hj-slave

在 HPM-gateway 仓库根目录执行，将源码只读挂载进容器，并把构建产物写到宿主机的 `build` 目录：

```sh
docker run --rm \
  -v "$PWD/hj-slave:/src:ro" \
  -v "$PWD/build:/build" \
  -w /src \
  xianii/hpm-dev-docker:latest \
  sh -c 'cmake -S . -B /build -GNinja \
    -DHPM_BUILD_TYPE=flash_xip \
    -DHPM_SOC_DISABLE_B_EXT=1 \
    -DCUSTOM_TARGET_TRIPLET=riscv-none-elf \
    -DRV_ARCH=rv32imac_zicsr_zifencei \
    "-DEXCLUDED_IDES=iar;ses" && \
    cmake --build /build --parallel 4'
```

成功后 ELF 位于 `build/output/hj_slave.elf`。首次编译需要下载的内容由 SDK 构建脚本处理，因此容器运行时需要网络访问。

镜像已将 `GNURISCV_TOOLCHAIN_PATH` 设为 `/opt/riscv`，并将工具加入 `PATH`。当前项目的 CMake 配置使用源码内的 `hj-slave/hpm_sdk_localized_for_hpm6e00evk`；将 `hj-slave` 挂载到 `/src` 后 SDK 路径自动可用，不必另挂完整 SDK。构建参数排除了 IAR 和 SES 工程生成，因此不需要安装 SES 或 IAR。若将镜像用于其他工程，需确保其 SDK 位于工程指定的 `HPM_SDK_BASE` 路径；不同 RISC-V 架构还可能需要在镜像中恢复相应 multilib。

## 自行构建镜像

在本目录执行：

```sh
docker build -t xianii/hpm-dev-docker:local .
```

然后将上面的 `docker run` 命令中的镜像标签替换为 `xianii/hpm-dev-docker:local`。Dockerfile 固定使用 xPack RISC-V GCC 13.2.0-2，并为减小体积移除了非 RV32IMAC 的 multilib。

## 自动发布到 Docker Hub

GitHub Actions 在推送到默认分支或推送 `v*` 标签时构建并发布镜像；Pull Request 只构建验证，不推送镜像。GitHub 仓库 `Nigh/hpm-dev-docker` 需要设置以下 Actions secrets：

- `DOCKERHUB_USERNAME`：Docker Hub 用户名。
- `DOCKERHUB_TOKEN`：Docker Hub access token（建议使用有权限范围限制的 token）。

不要把 Docker Hub token 写入仓库或提交到 Git。工作流发布到 `xianii/hpm-dev-docker`。
