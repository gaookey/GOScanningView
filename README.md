# GOScanningView

### 扫描 裁剪


### 部分属性和方法



初始化方法

```swift
/// 创建ScanningView
/// - Parameters:
///   - frame: frame
///   - isCycle: 是否循环/单次，默认true
///   - modeType: 扫描方向，默认upDown
///   - speedType: 扫描速度，默认linear
///   - gradientImageView: 扫尾图
///   - originalImage: 底图
///   - clipImage: 裁剪时，待裁剪图
///   - gradientSize: 扫尾大小，默认5
///   - duration: 扫描时间，默认1.5
///   - middleValue: 仅 ScanSpeedType 为 easeInEaseOut 或 easeInEaseOutReverse 时生效。默认中间位置
///   - noteValue: 预设通知值 0~1。扫描位置达到预设值时执行代理didNoteValue
public init(frame: CGRect, isCycle: Bool = true, modeType: GOScanModeType = .upDown, speedType: GOScanSpeedType = .linear, gradientImage: UIImage = UIImage(), originalImage: UIImage = UIImage(), clipImage: UIImage = UIImage(), gradientSize: CGFloat = 5, duration: CGFloat = 1.5, middleValue: CGFloat = 0, noteValue: CGFloat = 1)
```



循环裁剪时每次赋值刷新

```swift
var refreshImage: UIImage? 
```

原始底图

```swift
var originalImageView: UIImageView 
```

裁剪图

```swift
var clipImageView: UIImageView 
```

扫尾图

```swift
var gradientImageView: UIImageView 
```



###### 方法

开始动画
`isClip`: 是否裁剪。裁剪现仅支持 `linear` 状态

```swift
public func startScan(isClip: Bool = false) 
```

停止动画

```swift
public func stopScan() 
```

暂停动画

```swift
public func pauseScan() 
```

继续动画

```swift
public func playScan() 
```



扫描过程中的速度。默认 `linear`

`easeInEaseOut` 和 `easeInEaseOutReverse` 两种变速可以通过设置 `middleValue` 调整变速位置。默认中间位置

```swift
public enum GOScanSpeedType: Int {
    ///匀速
    case linear
    ///加速
    case easeIn
    ///减速
    case easeOut
    ///加速->减速
    case easeInEaseOut
    ///减速->加速
    case easeInEaseOutReverse
}
```



扫描方向。默认 `upDown`

```swift
public enum GOScanModeType: Int {
    ///上->下
    case upDown
    ///下->上
    case downUp
    ///左->右
    case leftRight
    ///右->左
    case rightLeft
}
```



##### 代理

`GOScanningViewDelegate`



```swift
    @objc optional func didCompletion(view: GOScanningView, isReversed: Bool)
    @objc optional func didChangeValue(view: GOScanningView, value: CGFloat)
    @objc optional func didNoteValue(view: GOScanningView, value: CGFloat)
```

