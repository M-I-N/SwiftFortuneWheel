//
//  SwiftFortuneWheel.swift
//  SwiftFortuneWheel
//
//  Created by Sherzod Khashimov on 5/28/20.
// 
//

import UIKit

@IBDesignable
/// Customizable Fortune spinning wheel control written in Swift.
public class SwiftFortuneWheel: UIControl {

    /// Called when spin button tapped
    public var onSpinButtonTap: (() -> Void)?

    /// Wheel view
    private var wheelView: WheelView?

    /// Pin image view
    private var pinImageView: PinImageView?

    /// Spin button
    private var spinButton: SpinButton?

    /// Animator
    lazy private var animator:SpinningWheelAnimator = SpinningWheelAnimator(withObjectToAnimate: self)

    /// Customizable configuration.
    /// Required in order to draw properly.
    public var configuration: SFWConfiguration? {
        didSet {
            updatePreferences()
        }
    }

    /// List of Slice objects.
    /// Used to draw content.
    open var slices: [Slice] = [] {
        didSet {
            self.wheelView?.slices = slices
        }
    }

    /// Pin image name from assets catalog
    private var _pinImageName: String? {
        didSet {
            pinImageView?.image(name: _pinImageName)
        }
    }

    /// Spin button image name from assets catalog
    private var _spinButtonImageName: String? {
        didSet {
            spinButton?.image(name: _spinButtonImageName)
        }
    }

    /// Spin button background image from assets catalog
    private var _spinButtonBackgroundImageName: String? {
        didSet {
            spinButton?.backgroundImage(name: _spinButtonImageName)
        }
    }

    /// Spin button title
    private var _spinTitle: String? {
        didSet {
            spinButton?.setTitle(_spinTitle, for: .normal)
        }
    }

    /// Initiates without IB.
    /// - Parameters:
    ///   - frame: Frame
    ///   - slices: List of Slices
    ///   - configuration: Customizable configuration
    public init(frame: CGRect, slices: [Slice], configuration: SFWConfiguration?) {
        self.configuration = configuration
        self.slices = slices
        self.wheelView = WheelView(frame: frame, slices: self.slices, preferences: self.configuration?.wheelPreferences)
        super.init(frame: frame)
        setupWheelView()
        setupPinImageView()
        setupSpinButton()
    }

    /// Adds pin image view to superview.
    /// Updates its layouts and image if needed.
    private func setupPinImageView() {
        guard let pinPreferences = configuration?.pinPreferences else {
            self.pinImageView = nil
            return
        }
        if self.pinImageView == nil {
            pinImageView = PinImageView()
        }
        if !self.isDescendant(of: pinImageView!) {
            self.addSubview(pinImageView!)
        }
        pinImageView?.setupAutoLayout(with: pinPreferences)
        pinImageView?.configure(with: pinPreferences)
        pinImageView?.image(name: _pinImageName)
    }

    /// Adds spin button  to superview.
    /// Updates its layouts and content if needed.
    private func setupSpinButton() {
        guard let spinButtonPreferences = configuration?.spinButtonPreferences else {
            self.spinButton = nil
            return
        }
        if self.spinButton == nil {
            spinButton = SpinButton()
        }
        if !self.isDescendant(of: spinButton!) {
            self.addSubview(spinButton!)
        }
        spinButton?.setupAutoLayout(with: spinButtonPreferences)
        DispatchQueue.main.async {
            self.spinButton?.setTitle(self.spinTitle, for: .normal)
            self.spinButton?.image(name: self._spinButtonImageName)
            self.spinButton?.backgroundImage(name: self._spinButtonBackgroundImageName)
        }
        spinButton?.configure(with: spinButtonPreferences)
        spinButton?.addTarget(self, action: #selector(spinAction), for: .touchUpInside)
    }

    @objc
    private func spinAction() {
        onSpinButtonTap?()
    }

    /// Adds spin button  to superview.
    /// Updates its layouts if needed.
    private func setupWheelView() {
        guard let wheelView = wheelView else { return }
        self.addSubview(wheelView)
        wheelView.setupAutoLayout()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.layer.needsDisplayOnBoundsChange = true
    }

    public required init?(coder aDecoder: NSCoder) {
        self.wheelView = WheelView(coder: aDecoder)
        super.init(coder: aDecoder)
        setupWheelView()
        setupPinImageView()
        setupSpinButton()
    }

    /// Updates subviews preferences
    private func updatePreferences() {
        self.wheelView?.preferences = configuration?.wheelPreferences
        setupPinImageView()
        setupSpinButton()
    }

}

extension SwiftFortuneWheel: SliceCalculating {}

extension SwiftFortuneWheel: SpinningAnimatorProtocol {

    //// Animation conformance
    internal var layerToAnimate: SpinningAnimatable? {
        return self.wheelView?.wheelLayer
    }
    
    
    /// Rotates to the specified index
    /// - Parameters:
    ///   - index: Index
    ///   - animationDuration: Animation duration
    open func rotate(toIndex index: Int, animationDuration: CFTimeInterval = 0.00001) {
        let _index = index < self.slices.count ? index : self.slices.count - 1
        let rotation = 360.0 - computeRadian(from: _index)
        guard animator.currentRotationPosition != rotation else { return }
        self.stopAnimating()
        self.animator.addRotationAnimation(fullRotationsUntilFinish: 0,
                                           animationDuration: animationDuration,
                                           rotationOffset: rotation,
                                           completionBlock: nil)
    }
    
    
    /// Rotates to the specified angle offset
    /// - Parameters:
    ///   - rotationOffset: Rotation offset
    ///   - animationDuration: Animation duration
    open func rotate(rotationOffset: CGFloat, animationDuration: CFTimeInterval = 0.00001) {
        guard animator.currentRotationPosition != rotationOffset else { return }
        self.stopAnimating()
        self.animator.addRotationAnimation(fullRotationsUntilFinish: 0,
                                           animationDuration: animationDuration,
                                           rotationOffset: rotationOffset,
                                           completionBlock: nil)
    }
    

    /// Starts rotation animation and stops rotation at the specified rotation offset angle
    /// - Parameters:
    ///   - rotationOffset: Rotation offset
    ///   - fullRotationsUntilFinish: Full rotations until start deceleration
    ///   - animationDuration: Animation duration
    ///   - completion: Completion handler
    open func startAnimating(rotationOffset: CGFloat, fullRotationsUntilFinish: Int = 13, animationDuration: CFTimeInterval = 5.000, _ completion: ((Bool) -> Void)?) {
        
        DispatchQueue.main.async {
            self.stopAnimating()
            self.animator.addRotationAnimation(fullRotationsUntilFinish: fullRotationsUntilFinish,
                                               animationDuration: animationDuration,
                                               rotationOffset: rotationOffset,
                                               completionBlock: completion)
        }
    }

    /// Starts rotation animation and stops rotation at the specified index
    /// - Parameters:
    ///   - finishIndex: Finish at index
    ///   - fullRotationsUntilFinish: Full rotations until start deceleration
    ///   - animationDuration: Animation duration
    ///   - completion: Completion handler
    open func startAnimating(finishIndex: Int, fullRotationsUntilFinish: Int = 13, animationDuration: CFTimeInterval = 5.000, _ completion: ((Bool) -> Void)?) {
        let _index = finishIndex < self.slices.count ? finishIndex : self.slices.count - 1
        let rotation = 360.0 - computeRadian(from: _index)
        self.startAnimating(rotationOffset: rotation,
                            fullRotationsUntilFinish: fullRotationsUntilFinish,
                            animationDuration: animationDuration,
                            completion)
    }


    /// Starts indefinite rotation and stops rotation at the specified index
    /// - Parameters:
    ///   - indefiniteRotationTimeInSeconds: full rotation time in seconds before stops
    ///   - finishIndex: finished at index
    ///   - completion: completion
    open func startAnimating(indefiniteRotationTimeInSeconds: Int, finishIndex: Int, _ completion: ((Bool) -> Void)?) {
        let _index = finishIndex < self.slices.count ? finishIndex : self.slices.count - 1
        self.startAnimating()
        let deadline = DispatchTime.now() + DispatchTimeInterval.seconds(indefiniteRotationTimeInSeconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.startAnimating(finishIndex: _index) { (finished) in
                completion?(finished)
            }
        }
    }

    /// Starts indefinite rotation animation
    open func startAnimating() {
        self.animator.addIndefiniteRotationAnimation()
    }

    /// Stops all animations
    open func stopAnimating() {
        self.layerToAnimate?.removeAllAnimations()
    }

    /// Starts rotation animation and stops rotation at the specified index and rotation angle offset
    /// - Parameters:
    ///   - finishIndex: finished at index
    ///   - rotationOffset: Rotation offset
    ///   - fullRotationsUntilFinish: Full rotations until start deceleration
    ///   - animationDuration: Animation duration
    ///   - completion: completion
    open func startAnimating(finishIndex: Int, rotationOffset: CGFloat, fullRotationsUntilFinish: Int = 13, animationDuration: CFTimeInterval = 5.000, _ completion: ((Bool) -> Void)?) {
        let _index = finishIndex < self.slices.count ? finishIndex : self.slices.count - 1
        let rotation = 360.0 - computeRadian(from: _index) + rotationOffset
        self.startAnimating(rotationOffset: rotation,
                            fullRotationsUntilFinish: fullRotationsUntilFinish,
                            animationDuration: animationDuration,
                            completion)
    }
}


public extension SwiftFortuneWheel {

    /// Pin image name from assets catalog, sets image to the `pinImageView`
    @IBInspectable var pinImage: String? {
        set { _pinImageName = newValue }
        get { return _pinImageName }
    }

    /// is `pinImageView` hidden
    @IBInspectable var isPinHidden: Bool {
        set { pinImageView?.isHidden = newValue }
        get { return pinImageView?.isHidden ?? false }
    }

    /// Spin button image name from assets catalog, sets image to the `spinButton`
    @IBInspectable var spinImage: String? {
        set { _spinButtonImageName = newValue }
        get { return _spinButtonImageName }
    }

    /// Spin button background image from assets catalog, sets background image to the `spinButton`
    @IBInspectable var spinBackgroundImage: String? {
        set { _spinButtonBackgroundImageName = newValue }
        get { return _spinButtonBackgroundImageName }
    }

    /// Spin button title text, sets title text to the `spinButton`
    @IBInspectable var spinTitle: String? {
        set { _spinTitle = newValue }
        get { return _spinTitle }
    }

    /// Is `spinButton` hidden
    @IBInspectable var isSpinHidden: Bool {
        set { spinButton?.isHidden = newValue }
        get { return spinButton?.isHidden ?? false }
    }

    /// Is `spinButton` enabled
    @IBInspectable var isSpinEnabled: Bool {
        set { spinButton?.isUserInteractionEnabled = newValue }
        get { return spinButton?.isUserInteractionEnabled ?? true }
    }
}
