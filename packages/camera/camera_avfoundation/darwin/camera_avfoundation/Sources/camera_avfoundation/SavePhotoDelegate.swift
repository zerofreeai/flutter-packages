// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import Flutter
import Foundation

/// The completion handler block for save photo operations.
/// Can be called from either main queue or IO queue.
/// If success, `path` will be present and `error` will be nil. Otherwise, `path` will be nil and
/// `error` will be present.
/// path - the path for successfully saved photo file.
/// error - photo capture error or IO error.
typealias SavePhotoDelegateCompletionHandler = (String?, Error?) -> Void

/// Delegate object that handles photo capture results.
class SavePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  /// The file path for the captured photo.
  private let path: String

  /// The queue on which captured photos are written to disk.
  private let ioQueue: DispatchQueue

  private let captureStartedAt = ProcessInfo.processInfo.systemUptime

  private func trace(_ stage: String) {
    NSLog(
      "ZeroPixNativeCapture %@ %@ %.3fms",
      (path as NSString).lastPathComponent, stage,
      (ProcessInfo.processInfo.systemUptime - captureStartedAt) * 1000)
  }

  /// The completion handler block for capture and save photo operations.
  let completionHandler: SavePhotoDelegateCompletionHandler

  /// The path for captured photo file.
  /// Exposed for unit tests to verify the captured photo file path.
  var filePath: String {
    path
  }

  /// Initialize a photo capture delegate.
  /// path - the path for captured photo file.
  /// ioQueue - the queue on which captured photos are written to disk.
  /// completionHandler - The completion handler block for save photo operations. Can
  /// be called from either main queue or IO queue.
  init(
    path: String,
    ioQueue: DispatchQueue,
    completionHandler: @escaping SavePhotoDelegateCompletionHandler
  ) {
    self.path = path
    self.ioQueue = ioQueue
    self.completionHandler = completionHandler
    super.init()
    trace("照片代理就绪")
  }

  /// Handler to write captured photo data into a file.
  /// - Parameters:
  ///   - error: The capture error
  ///   - photoDataProvider: A closure that provides photo data
  func handlePhotoCaptureResult(
    error: Error?,
    photoDataProvider: @escaping () -> WritableData?
  ) {
    if let error = error {
      completionHandler(nil, error)
      return
    }

    ioQueue.async { [weak self] in
      guard let strongSelf = self else { return }

      do {
        strongSelf.trace("文件队列开始")
        let data = photoDataProvider()
        strongSelf.trace("文件编码完成")
        try data?.writeToPath(strongSelf.path, options: .atomic)
        strongSelf.trace("文件写入完成")
        strongSelf.completionHandler(strongSelf.path, nil)
      } catch {
        strongSelf.completionHandler(nil, error)
      }
    }
  }

  // 系统曝光前后回调与照片处理分开计时，不能把文件返回延迟当作曝光延迟。
  func photoOutput(
    _ output: AVCapturePhotoOutput,
    willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
  ) {
    trace("即将曝光回调")
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
  ) {
    trace("已曝光回调")
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    trace("图像处理回调")
    handlePhotoCaptureResult(error: error) {
      photo.fileDataRepresentation()
    }
  }
}
