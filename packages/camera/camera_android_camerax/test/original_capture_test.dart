// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_android_camerax/camera_android_camerax.dart';
import 'package:camera_android_camerax/src/camerax_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'android_camera_camerax_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GenericsPigeonOverrides.observerNew = <T>({required void Function(Observer<T>, T) onChanged}) =>
        Observer<T>.detached(onChanged: onChanged);
  });
  tearDown(() {
    PigeonOverrides.pigeon_reset();
    GenericsPigeonOverrides.reset();
  });

  test('原片HDR绑定成功后同场景连续拍复用该用例', () async {
    final camera = AndroidCameraCameraX();
    final previous = MockImageCapture();
    final replacement = MockImageCapture();
    final provider = MockProcessCameraProvider();
    final native = MockCamera();
    final info = MockCameraInfo();
    final selector = MockCameraSelector();
    final orientation = MockDeviceOrientationManager();
    camera.imageCapture = previous;
    camera.processCameraProvider = provider;
    camera.cameraSelector = selector;
    camera.cameraInfo = info;
    PigeonOverrides.deviceOrientationManager_new = ({required onDeviceOrientationChanged}) =>
        orientation;
    when(provider.isBound(previous)).thenAnswer((_) async => true);
    when(provider.isBound(replacement)).thenAnswer((_) async => false);
    when(
      provider.bindToLifecycle(selector, <UseCase>[replacement]),
    ).thenAnswer((_) async => native);
    when(native.getCameraInfo()).thenAnswer((_) async => info);
    when(info.getCameraState()).thenAnswer((_) async => MockLiveCameraState());
    PigeonOverrides.imageCapture_new =
        ({resolutionSelector, targetRotation, flashMode, jpegQuality, originalCamera}) {
          expect(originalCamera, same(info));
          return replacement;
        };
    await camera.configureOriginalCapture(1, true);
    await camera.configureOriginalCapture(1, true);
    expect(camera.imageCapture, same(replacement));
    verify(provider.unbind(<UseCase>[previous])).called(1);
    verify(provider.bindToLifecycle(selector, <UseCase>[replacement])).called(1);
  });

  test('释放取景分析输出后HDR仍不可绑定时恢复原拍照用例', () async {
    final camera = AndroidCameraCameraX();
    final previous = MockImageCapture();
    final replacement = MockImageCapture();
    final analysis = MockImageAnalysis();
    final provider = MockProcessCameraProvider();
    final native = MockCamera();
    final info = MockCameraInfo();
    final selector = MockCameraSelector();
    camera.imageCapture = previous;
    camera.imageAnalysis = analysis;
    camera.processCameraProvider = provider;
    camera.cameraSelector = selector;
    camera.cameraInfo = info;
    PigeonOverrides.deviceOrientationManager_new = ({required onDeviceOrientationChanged}) =>
        MockDeviceOrientationManager();
    when(provider.isBound(previous)).thenAnswer((_) async => false);
    when(provider.isBound(analysis)).thenAnswer((_) async => true);
    when(
      provider.bindToLifecycle(selector, <UseCase>[replacement]),
    ).thenThrow(PlatformException(code: 'IllegalArgumentException'));
    when(provider.bindToLifecycle(selector, <UseCase>[previous])).thenAnswer((_) async => native);
    when(native.getCameraInfo()).thenAnswer((_) async => info);
    when(info.getCameraState()).thenAnswer((_) async => MockLiveCameraState());
    PigeonOverrides.imageCapture_new =
        ({resolutionSelector, targetRotation, flashMode, jpegQuality, originalCamera}) =>
            replacement;
    await camera.configureOriginalCapture(1, true);
    expect(camera.imageCapture, same(previous));
    verify(provider.unbind(<UseCase>[analysis])).called(1);
    verify(provider.bindToLifecycle(selector, <UseCase>[previous])).called(1);
  });
}
