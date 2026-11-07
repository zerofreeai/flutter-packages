// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation

/// 原生消费者返回 true 时接管该帧，插件不再复制或发送到 Dart。
/// 消费者若异步使用 sampleBuffer，必须持有它直到采样完成。
public enum CameraFrameTap {
  private static let lock = NSLock()
  private static var callback: ((CMSampleBuffer) -> Bool)?

  public static var consumer: ((CMSampleBuffer) -> Bool)? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return callback
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      callback = newValue
    }
  }

  static func consume(_ sampleBuffer: CMSampleBuffer) -> Bool {
    consumer?(sampleBuffer) ?? false
  }
}
