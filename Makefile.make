THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64
TARGET = iphone:clang:16.0:16.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FlashIsland26
FlashIsland26_FILES = Tweak.m
FlashIsland26_CFLAGS = -fobjc-arc
FlashIsland26_FRAMEWORKS = UIKit AVFoundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
