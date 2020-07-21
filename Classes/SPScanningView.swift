//
//  SPScanningView.swift
//  SPScanningView
//
//  Created by 高文立 on 2020/7/16.
//  Copyright © 2020 mouos. All rights reserved.
//

import UIKit

public enum ScanSpeedType: Int {
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

public enum ScanModeType: Int {
    ///上->下
    case upDown
    ///下->上
    case downUp
    ///左->右
    case leftRight
    ///右->左
    case rightLeft
}

public class SPScanningView: UIView {
    
    ///完成
    public var completionHandler: (() -> ())?
    ///达到设定预设值
    public var noteValueHandler: (() -> ())?
    
    ///预设通知值
    public var noteValue: CGFloat = 100000
    ///动画时间
    public var duration: CGFloat = 1.5
    ///是否循环
    public var isCycle = true
    ///仅 ScanSpeedType 为 easeInEaseOut 或 easeInEaseOutReverse 时生效。默认中间
    public var middleValue: CGFloat = 0 {
        didSet {
            configAttribute()
        }
    }
    ///扫尾的大小，默认5
    public var gradientSize: CGFloat = 5 {
        didSet {
            configAttribute()
        }
    }
    
    ///底图
    public var originalImage: UIImage? {
        willSet {
            if let image = newValue, isCompletion {
                originalImageView.image = image
            }
        }
    }
    
    ///原始底图
    public lazy var originalImageView = UIImageView(frame: bounds)
    ///裁剪图
    public lazy var clipImageView = UIImageView(frame: bounds)
    
    ///扫尾图
    public lazy var gradientImageView: UIImageView = {
        let image = UIImageView(frame: bounds)
        image.backgroundColor = .lightGray
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
    private var speedType: ScanSpeedType = .linear
    private var modeType: ScanModeType = .upDown
    private var isReversed = false
    private var speedTypeMiddleValue: CGFloat = 0
    private var isClip: Bool = false
    private var isCompletion = true
    private var presentationLink: CADisplayLink?
    
    public init(frame: CGRect, modeType: ScanModeType = .upDown, speedType: ScanSpeedType = .linear, originalImage: UIImage = UIImage(), clipImage: UIImage = UIImage()) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        
        self.modeType = modeType
        self.speedType = speedType
        self.originalImageView.image = originalImage
        self.clipImageView.image = clipImage
        
        configAttribute()
        
        addSubview(originalImageView)
        addSubview(clipView)
        clipView.addSubview(clipImageView)
        addSubview(gradientImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configAttribute() {
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
    
    ///开始动画
    public func startScan(isClip: Bool = false) {
        guard (gradientImageView.layer.animationKeys()?.count) == nil && (clipView.layer.animationKeys()?.count) == nil else { return }
        
        presentationLink?.invalidate()
        presentationLink = CADisplayLink(target: self, selector: #selector(presentationLinkAction))
        presentationLink?.add(to: RunLoop.current, forMode: .default)
        
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
    
    @objc func presentationLinkAction() {
        
        guard let frame = gradientImageView.layer.presentation()?.frame else {
            return
        }
        
        var value: CGFloat = 0
        
        switch modeType {
        case .upDown, .downUp:
            value = frame.origin.y
        case .leftRight, .rightLeft:
            value = frame.origin.x
        }
        
        if value >= noteValue {
            if let handler = noteValueHandler {
                presentationLink?.invalidate()
                handler()
            }
        }
    }
}

// MARK:  - clip
extension SPScanningView {
    
    func startClip() {
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
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = sizeValues.map{ $0 * 0.5 }
                } else {
                    originValues = getValues(min: 0, max: bounds.height, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.height / 2.0, max: bounds.height, temp: 0)
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
                    originValues = getValues(min: 0, max: bounds.height, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.height / 2.0, max: bounds.height, temp: 0)
                } else {
                    originValues = [0]
                    sizeValues = getValues(min: 0, max: bounds.height, isReversed: true, temp: 0)
                    pointValues = sizeValues.map{ $0 * 0.5 }
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
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = sizeValues.map{ $0 * 0.5 }
                } else {
                    originValues = getValues(min: 0, max: bounds.width, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.width / 2.0, max: bounds.width, temp: 0)
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
                    originValues = getValues(min: 0, max: bounds.width, temp: 0)
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = getValues(min: bounds.width / 2.0, max: bounds.width, temp: 0)
                } else {
                    originValues = [0]
                    sizeValues = getValues(min: 0, max: bounds.width, isReversed: true, temp: 0)
                    pointValues = sizeValues.map{ $0 * 0.5 }
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
        originAmin.fillMode = .forwards
        originAmin.isRemovedOnCompletion = false
        clipView.layer.add(sizeAnim, forKey: "clipSize")
        
        let pointAnim = CAKeyframeAnimation()
        pointAnim.keyPath = pointKeyPath
        pointAnim.duration = CFTimeInterval(duration)
        pointAnim.values = pointValues
        originAmin.fillMode = .forwards
        originAmin.isRemovedOnCompletion = false
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
        
        if let handler = completionHandler {
            handler()
        }
        
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
