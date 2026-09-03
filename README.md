# 驻迹

驻迹是一款原生 iPhone 旅行足迹日记。地图、定位、照片、日记与备份以隐私优先的方式设计，界面使用简体中文。

## 开发环境

- Xcode 16.4+
- iOS 17+
- Bundle ID：`com.xhshen.traveldiary`

运行 `xcodegen generate` 生成 Xcode 工程，然后打开 `ZhuJi.xcodeproj`。

地图由 Apple MapKit 提供，无需申请第三方地图密钥。天气印章使用 Open-Meteo 当前天气接口；足迹、日记与照片保存在本机。
