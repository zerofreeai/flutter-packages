// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation

/// 取景分析实验用的帧钩子（zeropix/camera-experiment 分支）。三个属性都不设置时插件行为不变。
public enum CameraFrameTap {
  /// 图像流开启期间，每个视频帧在送往 Dart 之前先交给它，在相机采集队列上同步调用。
  /// 返回 true 表示原生侧已接管该帧，插件不再拷贝、不再送往 Dart，也不占待确认帧名额。
  public static var consumer: ((CMSampleBuffer) -> Bool)?

  /// 帧送往 Dart 前调用，只观察不改变行为。`sequence` 自每次 startImageStream 起从 0 计数，
  /// 与 Dart 侧收到的帧一一对应；`callbackNs` 是进入采集回调的时刻，`copiedNs` 是像素拷贝完成的时刻，
  /// 均为 `DispatchTime.now().uptimeNanoseconds`。
  public static var forwarded:
    ((_ sequence: Int, _ sampleBuffer: CMSampleBuffer, _ callbackNs: UInt64, _ copiedNs: UInt64) ->
      Void)?

  /// 视频数据输出的缓冲尺寸（宽、高，与输出方向一致，画幅须与 activeFormat 相同）；
  /// nil 保持插件默认的全尺寸。预览纹理与图像流共用这路输出，须在创建相机前设置。
  public static var outputDimensions: (width: Int, height: Int)?

  static func videoSettings(format: FourCharCode) -> [String: Any] {
    var settings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: format]
    if let size = outputDimensions {
      settings[kCVPixelBufferWidthKey as String] = size.width
      settings[kCVPixelBufferHeightKey as String] = size.height
    }
    return settings
  }
}
