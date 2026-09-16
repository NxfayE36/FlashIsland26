# FlashIsland26

Rootless Theos tweak for iOS 16+ / arm64 that visually recreates the expanded iOS 18/26 flashlight Dynamic-Island controller on Home-button devices.

## Target
- iPhone 8 / 8 Plus / X-class A11 devices
- Dopamine rootless
- iOS 16.x
- Package architecture: iphoneos-arm64

## Important
The real Apple controller is tied to Dynamic Island devices and newer Adaptive True Tone Flash hardware. This tweak simulates the UI on older devices. The horizontal beam-width control is therefore visual unless the private `AVFlashlight` API exposes beam-width control on the device.

## Build
Install Theos and an Apple iOS SDK/toolchain, then:

`make package FINALPACKAGE=1`

The generated package is in `packages/`.
