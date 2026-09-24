FROM debian:bookworm-slim AS toolchain
# ponytail: HPM6E80 RV32IMAC only; keep/add multilibs if other targets are needed.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && mkdir -p /opt/riscv \
    && curl -fsSL https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz \
       | tar -xz --strip-components=1 -C /opt/riscv \
    && rm -rf /opt/riscv/riscv-none-elf/lib/rv* /opt/riscv/lib/gcc/riscv-none-elf/13.2.0/rv* \
    && rm -rf /var/lib/apt/lists/*

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake ninja-build python3 python3-yaml \
    && rm -rf /var/lib/apt/lists/*
COPY --from=toolchain /opt/riscv /opt/riscv

ENV GNURISCV_TOOLCHAIN_PATH=/opt/riscv
ENV PATH="/opt/riscv/bin:${PATH}"

WORKDIR /workspace
CMD ["sh"]
