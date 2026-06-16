# Mobile DAW development image: Flutter, Android SDK, CMake, Ninja, JDK 17

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG ANDROID_CMDLINE_VERSION=11076708
ARG FLUTTER_VERSION=3.32.4

# Base build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    curl \
    unzip \
    zip \
    git \
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/*

# Android SDK command-line tools
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# SDK packages and licenses
RUN yes | sdkmanager --licenses || true && \
    sdkmanager \
      "platform-tools" \
      "platforms;android-35" \
      "build-tools;35.0.0" \
      "ndk;27.2.12479018"

# Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    chown -R vscode:vscode ${FLUTTER_HOME}
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Pre-create common dirs
RUN mkdir -p /workspace && chown -R vscode:vscode /workspace ${ANDROID_HOME}

USER vscode
WORKDIR /workspace

RUN flutter config --no-analytics && \
    flutter precache --android
