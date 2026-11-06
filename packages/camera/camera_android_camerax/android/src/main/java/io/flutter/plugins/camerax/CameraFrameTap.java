// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camerax;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.camera.core.ImageProxy;

/** 让应用在帧送入 Dart 前接管缓冲，接管方负责关闭 ImageProxy。 */
public final class CameraFrameTap {
  private CameraFrameTap() {}

  public interface Consumer {
    /** 返回 true 后插件不再读取或释放这一帧。 */
    boolean consume(@NonNull ImageProxy image, long callbackNanos);
  }

  @Nullable public static volatile Consumer consumer;
}
