// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camerax;

import android.util.Size;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.camera.core.ImageProxy;

/** 取景分析实验用的帧钩子（zeropix/camera-experiment 分支）。三个字段都不设置时插件行为不变。 */
public final class CameraFrameTap {
  private CameraFrameTap() {}

  /** 原生侧接管帧。 */
  public interface Consumer {
    /**
     * 在分析器回调线程（主线程）上同步调用。返回 true 表示已接管：插件不再送往 Dart，由接管方负责关闭 image。
     *
     * @param callbackNanos 进入分析器回调的 {@link System#nanoTime()}
     */
    boolean consume(@NonNull ImageProxy image, long callbackNanos);
  }

  /** 只观察送往 Dart 的帧。 */
  public interface Observer {
    /**
     * @param sequence 自每次设置分析器起从 0 计数，与 Dart 侧收到的帧一一对应
     * @param callbackNanos 进入分析器回调的 {@link System#nanoTime()}
     */
    void forwarded(long sequence, @NonNull ImageProxy image, long callbackNanos);
  }

  @Nullable public static volatile Consumer consumer;
  @Nullable public static volatile Observer observer;

  /** ImageAnalysis 的目标分辨率；null 保持 Dart 侧传入的选择器。须在绑定用例前设置。 */
  @Nullable public static volatile Size analysisResolution;
}
