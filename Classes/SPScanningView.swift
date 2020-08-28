//
//  SPScanningView.swift
//  SPScanningView
//
//  Created by 高文立 on 2020/7/16.
//  Copyright © 2020 mouos. All rights reserved.
//

import UIKit

public enum SPScanSpeedType: Int {
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

public enum SPScanModeType: Int {
    ///上->下
    case upDown
    ///下->上
    case downUp
    ///左->右
    case leftRight
    ///右->左
    case rightLeft
}

public protocol SPScanningViewDelegate: NSObjectProtocol {
    func didCompletion(view: SPScanningView, isReversed: Bool)
    func didChangeValue(view: SPScanningView, value: CGFloat)
    func didNoteValue(view: SPScanningView, value: CGFloat)
}
public extension SPScanningViewDelegate {
    func didCompletion(view: SPScanningView, isReversed: Bool) { }
    func didChangeValue(view: SPScanningView, value: CGFloat) { }
    func didNoteValue(view: SPScanningView, value: CGFloat) { }
}

public class SPScanningView: UIView, SPScanningViewDelegate {
    
    weak open var delegate: SPScanningViewDelegate?
    
    ///循环裁剪时每次赋值刷新
    public var refreshImage: UIImage? {
        willSet {
            if let image = newValue, isCompletion {
                originalImageView.image = image
            }
        }
    }
    ///原始底图
    public lazy var originalImageView: UIImageView = {
        let image = UIImageView(frame: bounds)
        image.contentMode = .scaleAspectFill
        return image
    }()
    ///裁剪图
    public lazy var clipImageView: UIImageView = {
        let image = UIImageView(frame: bounds)
        image.contentMode = .scaleAspectFill
        return image
    }()
    ///扫尾图
    public lazy var gradientImageView: UIImageView = {
        let image = UIImageView(frame: bounds)
        image.backgroundColor = .lightGray
        image.contentMode = .scaleAspectFill
        image.layer.masksToBounds = true
        return image
    }()
    
    ///裁剪view
    private lazy var clipView: UIView = {
        let view = UIView(frame: bounds)
        view.layer.masksToBounds = true
        return view
    }()
    
    private var fromValue: CGFloat = 0
    private var toValue: CGFloat = 0
    private var speedType: SPScanSpeedType = .linear
    private var modeType: SPScanModeType = .upDown
    private var isReversed = false
    private var speedTypeMiddleValue: CGFloat = 0
    private var isClip: Bool = false
    private var isCompletion = true
    private var presentationLink: CADisplayLink?
    private var noteValue: CGFloat = 1
    private var duration: CGFloat = 1.5
    private var isCycle = true
    private var middleValue: CGFloat = 0
    private var gradientSize: CGFloat = 5
    
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
    public init(frame: CGRect, isCycle: Bool = true, modeType: SPScanModeType = .upDown, speedType: SPScanSpeedType = .linear, gradientImage: UIImage = UIImage(), originalImage: UIImage = UIImage(), clipImage: UIImage = UIImage(), gradientSize: CGFloat = 5, duration: CGFloat = 1.5, middleValue: CGFloat = 0, noteValue: CGFloat = 1) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        
        self.isCycle = isCycle
        self.modeType = modeType
        self.speedType = speedType
        self.gradientImageView.image = gradientImage
        if gradientImage.size != .zero {
            self.gradientImageView.backgroundColor = .clear
        }
        self.originalImageView.image = originalImage
        self.clipImageView.image = clipImage
        self.gradientSize = gradientSize
        self.duration = duration
        self.middleValue = middleValue
        self.noteValue = noteValue
        
        configAttribute()
        
        addSubview(originalImageView)
        addSubview(clipView)
        clipView.addSubview(clipImageView)
        addSubview(gradientImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configAttribute() {
        switch modeType {
        case .upDown:
            fromValue = -gradientSize * 0.5
            toValue = bounds.height + gradientSize * 0.5
            gradientImageView.frame = CGRect(x: 0, y: -gradientSize, width: bounds.width, height: gradientSize)
            speedTypeMiddleValue = middleValue == 0 ? bounds.height * 0.5 : middleValue
        case .downUp:
            fromValue = bounds.height + gradientSize * 0.5
            toValue = -gradientSize * 0.5
            gradientImageView.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: gradientSize)
            speedTypeMiddleValue = middleValue == 0 ? bounds.height * 0.5 : middleValue
        case .leftRight:
            fromValue = -gradientSize * 0.5
            toValue = bounds.width + gradientSize * 0.5
            gradientImageView.frame = CGRect(x: -gradientSize, y: 0, width: gradientSize, height: bounds.height)
            speedTypeMiddleValue = middleValue == 0 ? bounds.width * 0.5 : middleValue
        case .rightLeft:
            fromValue = bounds.width + gradientSize * 0.5
            toValue = -gradientSize * 0.5
            gradientImageView.frame = CGRect(x: bounds.width, y: 0, width: gradientSize, height: bounds.height)
            speedTypeMiddleValue = middleValue == 0 ? bounds.width * 0.5 : middleValue
        }
    }
}

// MARK: - scan
extension SPScanningView {
    
    /// 开始动画
    /// - Parameter isClip: 是否裁剪。裁剪现仅支持 linear 状态
    public func startScan(isClip: Bool = false) {
        guard (gradientImageView.layer.animationKeys()?.count) == nil && (clipView.layer.animationKeys()?.count) == nil else { return }
        
        presentationLink?.invalidate()
        presentationLink = CADisplayLink(target: self, selector: #selector(presentationLinkAction))
        presentationLink?.add(to: RunLoop.current, forMode: .default)
        
        if isClip {
            self.speedType = .linear
        }
        self.isClip = isClip
        isCompletion = false
        startScan(fromValue, toValue)
    }
    
    ///停止动画
    public func stopScan() {
        isReversed = false
        isCompletion = true
        gradientImageView.transform = CGAffineTransform.identity
        gradientImageView.layer.removeAllAnimations()
        clipView.transform = CGAffineTransform.identity
        clipView.layer.removeAllAnimations()
        presentationLink?.invalidate()
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
    }
    ///暂停动画
    public func pauseScan() {
        guard layer.speed == 1 && !isCompletion else {
            return
        }
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }
    
    ///继续动画
    public func playScan() {
        guard layer.speed == 0 && !isCompletion else {
            return
        }
        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}

extension SPScanningView {
    
    private func startScan(_ from: CGFloat, _ to: CGFloat) {
        
        let path = CGMutablePath()
        animationPath(path, from, to)
        
        let scanningAnim = CAKeyframeAnimation()
        scanningAnim.keyPath = "position"
        scanningAnim.duration = CFTimeInterval(duration)
        scanningAnim.path = path
        scanningAnim.fillMode = .forwards
        scanningAnim.isRemovedOnCompletion = false
        scanningAnim.delegate = self
        gradientImageView.layer.add(scanningAnim, forKey: "scanning")
        
        if isClip {
            startClip()
        }
    }
    
    @objc private func presentationLinkAction() {
        
        guard let frame = gradientImageView.layer.presentation()?.frame else {
            return
        }
        
        var value: CGFloat = 0
        var note: CGFloat = 0
        switch modeType {
        case .upDown, .downUp:
            value = frame.origin.y
            note = noteValue * bounds.height
        case .leftRight, .rightLeft:
            value = frame.origin.x
            note = noteValue * bounds.width
        }
        
        delegate?.didChangeValue(view: self, value: value)
        
        if modeType == .upDown || modeType == .leftRight {
            if value >= note {
                delegate?.didNoteValue(view: self, value: note)
                presentationLink?.invalidate()
            }
        } else if modeType == .downUp || modeType == .rightLeft {
            if value <= note {
                delegate?.didNoteValue(view: self, value: note)
                presentationLink?.invalidate()
            }
        }
    }
}

// MARK:  - clip
extension SPScanningView {
    
    private func startClip() {
        
        var originValues = [CGFloat]()
        var sizeValues = [CGFloat]()
        var pointValues = [CGFloat]()
        
        var originKeyPath = ""
        var sizeKeyPath = ""
        var pointKeyPath = ""
        
        if modeType == .upDown {
            if speedType == .linear {
                if isReversed {
                    originValues = [0]
                    sizeValues = getValues(min: -gradientSize, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: -gradientSize / 2.0, max: bounds.height / 2.0, isReversed: true, temp: 0)
                } else {
                    originValues = getValues(min: 0, max: bounds.height + gradientSize, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.height / 2.0, max: bounds.height + gradientSize, temp: 0)
                }
                
                originKeyPath = "bounds.origin.y"
                sizeKeyPath = "bounds.size.height"
                pointKeyPath = "position.y"
            } else if speedType == .easeIn {
                
            } else if speedType == .easeOut {
                
            } else if speedType == .easeInEaseOut {
                
            } else if speedType == .easeInEaseOutReverse {
                
            }
        } else if modeType == .downUp {
            if speedType == .linear {
                if isReversed {
                    originValues = getValues(min: 0, max: bounds.height + gradientSize, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.height / 2.0, max: bounds.height + gradientSize, temp: 0)
                } else {
                    originValues = [0]
                    sizeValues = getValues(min: -gradientSize, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: -gradientSize / 2.0, max: bounds.height / 2.0, isReversed: true, temp: 0)
                }
                
                originKeyPath = "bounds.origin.y"
                sizeKeyPath = "bounds.size.height"
                pointKeyPath = "position.y"
            } else if speedType == .easeIn {
                
            } else if speedType == .easeOut {
                
            } else if speedType == .easeInEaseOut {
                
            } else if speedType == .easeInEaseOutReverse {
                
            }
        } else if modeType == .leftRight {
            if speedType == .linear {
                if isReversed {
                    originValues = [0]
                    sizeValues = getValues(min: -gradientSize, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: -gradientSize / 2.0, max: bounds.width / 2.0, isReversed: true, temp: 0)
                } else {
                    originValues = getValues(min: 0, max: bounds.width + gradientSize, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.width / 2.0, max: bounds.width + gradientSize, temp: 0)
                }
                
                originKeyPath = "bounds.origin.x"
                sizeKeyPath = "bounds.size.width"
                pointKeyPath = "position.x"
            } else if speedType == .easeIn {
                
            } else if speedType == .easeOut {
                
            } else if speedType == .easeInEaseOut {
                
            } else if speedType == .easeInEaseOutReverse {
                
            }
        } else if modeType == .rightLeft {
            if speedType == .linear {
                if isReversed {
                    originValues = getValues(min: 0, max: bounds.width + gradientSize, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.width / 2.0, max: bounds.width + gradientSize, temp: 0)
                } else {
                    originValues = [0]
                    sizeValues = getValues(min: -gradientSize, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: -gradientSize / 2.0, max: bounds.width / 2.0, isReversed: true, temp: 0)
                }
                
                originKeyPath = "bounds.origin.x"
                sizeKeyPath = "bounds.size.width"
                pointKeyPath = "position.x"
            } else if speedType == .easeIn {
                
            } else if speedType == .easeOut {
                
            } else if speedType == .easeInEaseOut {
                
            } else if speedType == .easeInEaseOutReverse {
                
            }
        }
        
        let originAmin = CAKeyframeAnimation()
        originAmin.keyPath = originKeyPath
        originAmin.duration = CFTimeInterval(duration)
        originAmin.values = originValues
        originAmin.fillMode = .forwards
        originAmin.isRemovedOnCompletion = false
        clipView.layer.add(originAmin, forKey: "clipOrigin")
        
        let sizeAnim = CAKeyframeAnimation()
        sizeAnim.keyPath = sizeKeyPath
        sizeAnim.duration = CFTimeInterval(duration)
        sizeAnim.values = sizeValues
        sizeAnim.fillMode = .forwards
        sizeAnim.isRemovedOnCompletion = false
        clipView.layer.add(sizeAnim, forKey: "clipSize")
        
        let pointAnim = CAKeyframeAnimation()
        pointAnim.keyPath = pointKeyPath
        pointAnim.duration = CFTimeInterval(duration)
        pointAnim.values = pointValues
        pointAnim.fillMode = .forwards
        pointAnim.isRemovedOnCompletion = false
        clipView.layer.add(pointAnim, forKey: "clipPoint")
    }
}

// MARK: - CAAnimationDelegate
extension SPScanningView: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        guard flag else {
            return
        }
        
        isCompletion = true
        
        if isClip {
            clipImageView.image = originalImageView.image
        }
        
        delegate?.didCompletion(view: self, isReversed: isReversed)
        
        guard isCycle else {
            stopScan()
            return
        }
        
        let animation: CAKeyframeAnimation = anim as! CAKeyframeAnimation
        let currentPoint =  animation.path?.currentPoint
        
        var value: CGFloat?
        
        switch modeType {
        case .upDown, .downUp:
            value = currentPoint?.y
        case .leftRight, .rightLeft:
            value = currentPoint?.x
        }
        
        if value == fromValue {
            isReversed = false
            gradientImageView.transform = CGAffineTransform.identity
            startScan(fromValue, toValue)
        } else {
            isReversed = true
            gradientImageView.transform = CGAffineTransform(rotationAngle: .pi)
            startScan(toValue, fromValue)
        }
    }
}

// MARK: - scan
extension SPScanningView {
    
    ///加速
    private func easeInPath(_ path: CGMutablePath, _ from: CGFloat, _ to: CGFloat) {
        
        var judge = false
        
        if modeType == .upDown || modeType == .leftRight {
            judge = !isReversed
        } else if modeType == .downUp || modeType == .rightLeft {
            judge = isReversed
        }
        
        let values = getValues(min: min(from, to), max: max(from, to), isIncreasing: judge)
        addLinePath(path, values)
    }
    
    ///减速
    private func easeOutPath(_ path: CGMutablePath, _ from: CGFloat, _ to: CGFloat) {
        
        var judge = false
        
        if modeType == .upDown || modeType == .leftRight {
            judge = isReversed
        } else if modeType == .downUp || modeType == .rightLeft {
            judge = !isReversed
        }
        
        let values = getValues(min: min(from, to), max: max(from, to), isIncreasing: judge, isReversed: true)
        addLinePath(path, values)
    }
    
    ///加速->减速
    private func easeInEaseOutPath(_ path: CGMutablePath, _ from: CGFloat, _ to: CGFloat) {
        
        var judge = false
        var judge2 = false
        
        if modeType == .upDown || modeType == .leftRight {
            judge = !isReversed
            judge2 = isReversed
        } else if modeType == .downUp || modeType == .rightLeft {
            judge = isReversed
            judge2 = !isReversed
        }
        
        let values = getValues(min: min(from, speedTypeMiddleValue), max: max(from, speedTypeMiddleValue), isIncreasing: judge)
        addLinePath(path, values)
        
        let values2 = getValues(min: min(speedTypeMiddleValue, to), max: max(speedTypeMiddleValue, to), isIncreasing: judge2, isReversed: true)
        for i in 0..<values2.count {
            if modeType == .leftRight || modeType == .rightLeft {
                path.addLine(to: CGPoint(x: values2[i], y: bounds.height * 0.5))
            } else {
                path.addLine(to: CGPoint(x: bounds.width * 0.5, y: values2[i]))
            }
        }
    }
    
    ///减速->加速
    private func easeInEaseOutReversePath(_ path: CGMutablePath, _ from: CGFloat, _ to: CGFloat) {
        
        var judge = false
        var judge2 = false
        
        if modeType == .upDown || modeType == .leftRight {
            judge = isReversed
            judge2 = !isReversed
        } else if modeType == .downUp || modeType == .rightLeft {
            judge = !isReversed
            judge2 = isReversed
        }
        
        let values = getValues(min: min(from, speedTypeMiddleValue), max: max(from, speedTypeMiddleValue), isIncreasing: judge, isReversed: true)
        addLinePath(path, values)
        
        let values2 = getValues(min: min(speedTypeMiddleValue, to), max: max(speedTypeMiddleValue, to), isIncreasing: judge2)
        for i in 0..<values2.count {
            if modeType == .leftRight || modeType == .rightLeft {
                path.addLine(to: CGPoint(x: values2[i], y: bounds.height * 0.5))
            } else {
                path.addLine(to: CGPoint(x: bounds.width * 0.5, y: values2[i]))
            }
        }
    }
    
    private func addLinePath(_ path: CGMutablePath, _ values: [CGFloat]) {
        
        for i in 0..<values.count {
            if modeType == .leftRight || modeType == .rightLeft {
                path.addLine(to: CGPoint(x: values[i], y: bounds.height * 0.5))
            } else {
                path.addLine(to: CGPoint(x: bounds.width * 0.5, y: values[i]))
            }
        }
    }
    
    private func animationPath(_ path: CGMutablePath, _ from: CGFloat, _ to: CGFloat) {
        
        if modeType == .upDown || modeType == .downUp {
            path.move(to: CGPoint(x: bounds.width * 0.5, y: from))
            
            if speedType == .linear {
                path.addLine(to: CGPoint(x: bounds.width * 0.5, y: to))
            }
        } else if modeType == .leftRight || modeType == .rightLeft {
            path.move(to: CGPoint(x: from, y: bounds.height * 0.5))
            
            if speedType == .linear {
                path.addLine(to: CGPoint(x: to, y: bounds.height * 0.5))
            }
        }
        
        if speedType == .easeIn {
            easeInPath(path, from, to)
        } else if speedType == .easeOut {
            easeOutPath(path, from, to)
        } else if speedType == .easeInEaseOut {
            easeInEaseOutPath(path, from, to)
        } else if speedType == .easeInEaseOutReverse {
            easeInEaseOutReversePath(path, from, to)
        }
    }
}

extension SPScanningView {
    
    private func getValues(min: CGFloat, max: CGFloat, isIncreasing: Bool = true, isReversed: Bool = false, temp: CGFloat = 1) -> [CGFloat] {
        
        var value: CGFloat = isIncreasing ? min : max
        var tempValue: CGFloat = 1
        var values = [isIncreasing ? min : max]
        
        for _ in 0...Int.max {
            tempValue += temp
            isIncreasing ? (value += tempValue) : (value -= tempValue)
            
            let bb = isIncreasing ? (value < max) : (value > min)
            if bb {
                values.append(value)
            } else {
                values.append(isIncreasing ? max : min)
                break
            }
        }
        
        return isReversed ? values.reversed() : values
    }
}
