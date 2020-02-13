FROM nvidia/cuda:10.1-devel-ubuntu18.04 as builder

MAINTAINER Terry Wong

WORKDIR /tmp

RUN apt-get update && apt-get install -y git make yasm pkg-config

RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers \
  && cd nv-codec-headers \
  && git checkout sdk/9.0 \
  && make install

RUN git clone https://git.ffmpeg.org/ffmpeg.git \
  && cd ffmpeg \
  && git checkout 018a427 \
  && ./configure --enable-cuda --enable-cuvid --enable-nvenc --enable-nonfree --enable-libnpp --extra-cflags=-I/usr/local/cuda/include  --extra-ldflags=-L/usr/local/cuda/lib64 \
  && make -j -s

FROM nvidia/cuda:10.1-runtime-ubuntu18.04

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,video,utility

COPY --from=builder /tmp/ffmpeg/ffmpeg /usr/local/bin/ffmpeg
COPY --from=builder /tmp/ffmpeg/ffprobe /usr/local/bin/ffprobe

RUN apt-get update && apt-get install curl

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
