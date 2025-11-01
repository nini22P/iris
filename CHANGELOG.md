## v1.5.2

### Changelog

* Migrate to MPL-2.0 license
* Add more media type support
* Fix key open subtitle and audio track issue
* Fix popup layer cannot be closed with `Esc` key issue

### 更新日志

* 迁移到 MPL-2.0 许可证
* 添加更多媒体类型支持
* 修复按键打开字幕和音频轨道的问题
* 修复弹出层无法使用 `Esc` 键关闭的问题

## v1.5.1

### Changelog

* Adjusted the playback control bar style in compact layout
* Clicking “Check update” in the Microsoft Store version redirects to the Store page
* Fixed forward and backward issues

### 更新日志

* 调整了紧凑布局下的播放控制栏样式
* 微软商店版本中点击检查更新将跳转至商店页面
* 修复了快退快进的问题

## v1.5.0

### Changelog

* Updated app icon
* Added a stop and an exit button
* Added a playback-speed selector that activates with a touch-and-hold gesture
* Fixed URI handling
* Improved stability and performance

### 更新日志

* 更换应用图标
* 添加停止按钮和退出按钮
* 添加触控长按激活的播放速度选择器
* 修复 uri 处理
* 优化了稳定性和性能

## v1.4.2

### Changelog

* Fix audio cover issue
* Improve uri handling

### 更新日志

* 修复音频封面问题
* 改进 uri 处理

## v1.4.1

### Changelog

* Dynamic FTP streaming url

### 更新日志

* FTP 串流使用动态 url

## v1.4.0

### Changelog

* Supports FTP storage
* Supports adding local folders to the storage list
* Storage list support remote disk and network shortcuts on Windows
* Add Windows installer

### 更新日志

* 支持 FTP 存储
* 支持添加本地文件夹到存储列表
* Windows 版本存储列表支持远程磁盘和网络快捷方式
* 添加 Windows 版本安装器

## v1.3.4

### Changelog

* The Android version allows you to set the screen orientation.
* Add playback speed button.
* Add hotkeys: Step forward `+`, Step backward `-`.

### 更新日志

* 安卓版本可以设置屏幕方向。
* 添加播放速度按钮。
* 添加快捷键：帧进 `+`，帧退 `-`。

## v1.3.3

### Changelog

* Fix issue of not being able to continue playback after startup

### 更新日志

* 修复启动后无法继续播放的问题

## v1.3.2

### Changelog

* Support for custom https ports when adding WebDAV storage

### 更新日志

* 添加 WebDAV 存储时支持自定义 https 端口

## v1.3.1

### Changelog

* The data save location for the Windows version has been changed to `C:\Users\<user>\AppData\Roaming\nini22P\iris`
* Updated upstream dependencies and fixed the issue with switching subtitles in the FVP player backend

### 更新日志

* Windows 版本数据保存位置已修改为 `C:\Users\<user>\AppData\Roaming\nini22P\iris`
* 更新上游依赖，修复 FVP 播放器后端切换字幕的问题

## v1.3.0

### Changelog

* Add [FVP](https://github.com/wang-bin/fvp) player backend (Experimental, with unknown bugs)
* Adding volume adjust
* Add file sort
* Add hotkeys: Volume up ( `Arrow Up` ), Volume down ( `Arrow Down` ), Volume mute ( `Ctrl + M` ), Toggle always on top ( `F10` ), Close currently media file ( `Ctrl + C` ), Exit application ( `Alt + X` )
* Improved some visual effects

### 更新日志

* 添加 [FVP](https://github.com/wang-bin/fvp) 播放器后端（实验性，有未知bug）
* 添加音量调整
* 添加文件排序
* 添加快捷键：提升音量（ `Arrow Up` ）、降低音量（ `Arrow Down` ）、静音（`Ctrl + M`）、切换窗口置顶（ `F10` ）、关闭当前媒体文件（ `Ctrl + C` ）、退出应用（ `Alt + X` ）
* 改进了部分视觉效果

## v1.2.1

### Changelog

* Split APKs by architecture to reduce installation size.

### 更新日志

* 拆分不同架构的 APK 以减小安装包大小

## v1.2.0

### Changelog

* Support jumping to video playback from external clicks (Windows version can play by command line or dragging files to the window)
* Support adjusting brightness and volume gestures (Brightness gestures are not available on Windows version)
* Support playing online links
* Add an option to always start playback from the beginning
* On Android 11 and above, file reading is changed to using the "Manage All Files" permission
* Improved WebDAV connection test function
* Improved some visual effects

### 更新日志

* 支持从外部点击视频跳转播放（Windows 版本可以通过命令行或者拖拽文件到窗口播放）
* 支持调整亮度和音量手势（Windows 版本调整亮度手势不可用）
* 支持播放在线链接
* 添加总是从头开始播放的选项
* Android 11 以上读取文件时改为使用 `管理所有文件` 权限
* 改进 WebDAV 测试连接功能
* 改进了部分视觉效果

## v1.1.1

### Changelog

* Restore old update method for windows version (Double-click the `iris-updater.bat` in the same directory as the executable file to upgrade if you have problems updating.)

### 更新日志

* windows 版本恢复为旧的更新方式（更新出问题的可双击打开可执行文件同级目录下的 `iris-updater.bat` 升级）

## v1.1.0

### Breaking Changes

* All configurations will be cleared. Please reconfigure

### Changlog

* Display all local storage
* Support playback history
* Support random playback
* Support loop playback
* Support video zoom

### 重大变更

* 所有配置将被清空，请重新配置

### 更新日志

* 显示所有本地存储
* 支持播放历史
* 支持随机播放
* 支持循环播放
* 支持视频缩放

## v1.0.3

### Changelog

* Improve Windows version installation updates
* Fixes an issue where subtitles may not be found

### 更新日志

* 改进 Windows 版本安装更新
* 修复可能无法找到字幕的问题

## v1.0.2

### Changelog

* Support for switching built-in audio tracks
* Reduce package size for Windows version

### 更新日志

* 支持切换内置音轨
* 减小 Windows 版本包体大小

## v1.0.1

### Changelog

* Windows version support auto update

### 更新日志

* Windows 版本支持自动更新

## v1.0.0

### Changelog

* Supports WebDAV and local storage video playback

### 更新日志

* 支持 WebDAV 和本地存储视频播放
