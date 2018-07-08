//
//  RangeSlider.swift
//  SwiftRangeSlider
//
//  Created by Brian Corbin on 5/22/16.
//  Copyright © 2016 Caramel Apps. All rights reserved.
//

import UIKit
import QuartzCore

///Class that represents the RangeSlider object.
@IBDesignable open class RangeSlider: UIControl {
  
  // MARK: - Properties
  
  ///The minimum value selectable on the RangeSlider
  @IBInspectable open var minimumValue: Double = 0.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The maximum value selectable on the RangeSlider
  @IBInspectable open var maximumValue: Double = 10.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The minimum difference in value between the Knobs. `0.0` is both default and disabled
  @IBInspectable open var minimumDistance: Double = 0.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The current lower value selected on the RangeSlider
  @IBInspectable open var lowerValue: Double = 2.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The current upper value selected on the RangeSlider
  @IBInspectable open var upperValue: Double = 8.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The minimum value a Knob can change. Default and minimum of 0
  @IBInspectable open var stepValue: Double = 0.0 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///The color of the track bar outside of the selected range
  @IBInspectable open var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
    didSet {
      track.setNeedsDisplay()
    }
  }
  
  ///The color of the track bar within the selected range
  @IBInspectable open var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
    didSet {
      track.setNeedsDisplay()
    }
  }
  
  ///The thickness of the track bar. `0.05` by default.
  @IBInspectable open var trackThickness: CGFloat = 0.05 {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///Whether the track thickness is true or proportional to its containers frame height
  @IBInspectable open var trueTrackThickness: Bool = false {
    didSet {
      updateTrackLayerFrameAndKnobPositions()
    }
  }
  
  ///Whether or not you can drag the highlighted area to move both Knobs at the same time.
  @IBInspectable open var dragTrack: Bool = false
  
  ///The diameter of the Knob. '0.95' by default.
  @IBInspectable open var knobSize: CGFloat = 0.95 {
    didSet {
      updateLayerFramesAndPositions()
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///Whether the Knob size is true or proportional to its containers frame height.
  @IBInspectable open var trueKnobSize: Bool = false {
    didSet {
      updateLayerFramesAndPositions()
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///The color of the slider buttons. `White` by default.
  @IBInspectable open var knobTintColor: UIColor = UIColor.white {
    didSet {
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///The thickness of the slider buttons border. `0.1` by default.
  @IBInspectable open var knobBorderThickness: CGFloat = 0.1 {
    didSet {
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///The color of the Knob borders. `UIColor.gray` by default.
  @IBInspectable open var knobBorderTintColor: UIColor = UIColor.gray {
    didSet {
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsLayout()
    }
  }
  
  ///The size to multiply the Knob by on selection. `1.0` by default.
  @IBInspectable open var selectedKnobDiameterMultiplier: CGFloat = 1.0 {
    didSet {
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsLayout()
    }
  }
  
  ///Whether or not the slider buttons have a shadow. `true` by default.
  @IBInspectable open var knobHasShadow: Bool = true {
    didSet{
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///The curvaceousness of the ends of the track bar and the slider buttons. `1.0` by default.
  @IBInspectable open var curvaceousness: CGFloat = 1.0 {
    didSet {
      track.setNeedsDisplay()
      lowerKnob.setNeedsDisplay()
      upperKnob.setNeedsDisplay()
    }
  }
  
  ///The font size of the labels. `12.0` by default.
  @IBInspectable open var labelFontSize: CGFloat = 12.0 {
    didSet {
      updateLabelText()
      updateLabelPositions()
    }
  }
  
  ///The color of the labels. `UIColor.clear` by default.
  @IBInspectable open var labelColor: UIColor = UIColor.clear {
    didSet {
      updateLabelText()
    }
  }
  
  ///Whether the labels are hidden or not. `false` by default.
  @IBInspectable open var hideLabels: Bool = false {
    didSet {
      updateLabelText()
    }
  }
  
  var previousLocation = CGPoint()
  var previouslySelectedKnob = Knob.Neither
  
  var lowerLabelTextSize: CGSize!
  var upperLabelTextSize: CGSize!
  
  let track = RangeSliderTrack()
  let lowerKnob = RangeSliderKnob()
  let upperKnob = RangeSliderKnob()
  let lowerLabel = CATextLayer()
  let upperLabel = CATextLayer()
  
  var TrackThickness: CGFloat {
    get {
      return trueTrackThickness ? trackThickness : trackThickness * bounds.height
    }
  }
  
  var KnobSize: CGFloat {
    get {
      return trueKnobSize ? knobSize : knobSize * bounds.height
    }
  }
  
  ///The frame of the `RangeSlider` instance.
  override open var frame: CGRect {
    didSet {
      updateLayerFramesAndPositions()
    }
  }
    
    var trackRange: Double {
        return maximumValue - minimumValue
    }
    
    var knobsAreClose: Bool {
        return lowerValue + trackRange * 0.05 >= upperValue
    }
    
    var knobsAreCloserToMinimum: Bool {
        return maximumValue - upperValue > lowerValue - minimumValue
    }
    
  
  // MARK: - Lifecycle
  
  /**
   Initializes the `RangeSlider` instance with the specified frame.
   
   - returns: The new `RangeSlider` instance.
   */
  override public init(frame: CGRect) {
    super.init(frame: frame)
    addContentViews()
  }
  
  /**
   Initializes the `RangeSlider` instance from the storyboard.
   
   - returns: The new `RangeSlider` instance.
   */
  required public init(coder: NSCoder) {
    super.init(coder: coder)!
    addContentViews()
  }
  
  func addContentViews(){
    track.rangeSlider = self
    track.contentsScale = UIScreen.main.scale
    layer.addSublayer(track)
    
    lowerKnob.frame = CGRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
    lowerKnob.rangeSlider = self
    lowerKnob.contentsScale = UIScreen.main.scale
    layer.addSublayer(lowerKnob)
    
    upperKnob.frame = CGRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
    upperKnob.rangeSlider = self
    upperKnob.contentsScale = UIScreen.main.scale
    layer.addSublayer(upperKnob)
    
    lowerLabel.alignmentMode = kCAAlignmentCenter
    lowerLabel.fontSize = labelFontSize
    lowerLabel.frame = CGRect(x: 0, y: 0, width: 75, height: labelFontSize)
    lowerLabel.contentsScale = UIScreen.main.scale
    lowerLabel.font = UIFont.systemFont(ofSize: labelFontSize)
    lowerLabel.foregroundColor = labelColor.cgColor
    layer.addSublayer(lowerLabel)
    
    upperLabel.alignmentMode = kCAAlignmentCenter
    upperLabel.fontSize = labelFontSize
    upperLabel.frame = CGRect(x: 0, y: 0, width: 75, height: labelFontSize)
    upperLabel.contentsScale = UIScreen.main.scale
    upperLabel.font = UIFont.systemFont(ofSize: labelFontSize)
    upperLabel.foregroundColor = labelColor.cgColor
    layer.addSublayer(upperLabel)
  }
  
  // MARK: Member Functions
  
  open func updateLayerFramesAndPositions() {
    lowerKnob.frame = CGRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
    upperKnob.frame = CGRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
    updateTrackLayerFrameAndKnobPositions()
  }
  
  ///Updates the tracks layer frame and the knobs positions.
  open func updateTrackLayerFrameAndKnobPositions() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let newTrackDy = (frame.height - TrackThickness) / 2
    track.frame = CGRect(x: 0, y: newTrackDy, width: frame.width, height: TrackThickness)
    track.setNeedsDisplay()
    
    let lowerKnobCenter = positionForValue(lowerValue)
    lowerKnob.position = lowerKnobCenter
    lowerKnob.setNeedsDisplay()
    
    let upperKnobCenter = positionForValue(upperValue)
    upperKnob.position = upperKnobCenter
    upperKnob.setNeedsDisplay()
    
    updateLabelText()
    updateLabelPositions()
    CATransaction.commit()
  }
    
    /**
     Get the label text for a given value.
     
     - parameters:
        - value: The lower or upper value.
     
     - returns: Text for lower or upper label.
     
     Breaking out this functionality from 'updateLabelText()' allows a subclass of RangeSlider to override this method and provide custom text. For example, if the slider is representing centimeters of snow, the override function could return "\(value)cm" instead of just "\(value)". Or it could modify the number of decimals shown.
     */
    open func getLabelText(forValue value: Double) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 0
        guard let labelText = numberFormatter.string(from: NSNumber(value: value)) else { return "" }
        
        return labelText
    }
  
  ///Updates the labels text content.
  open func updateLabelText() {
    if hideLabels {
      lowerLabel.string = ""
      upperLabel.string = ""
      return
    }
    
    lowerLabel.fontSize = labelFontSize
    upperLabel.fontSize = labelFontSize
    
    lowerLabel.string = getLabelText(forValue: lowerValue)
    upperLabel.string = getLabelText(forValue: upperValue)
    
    lowerLabel.foregroundColor = labelColor.cgColor
    upperLabel.foregroundColor = labelColor.cgColor
    
    lowerLabelTextSize = (lowerLabel.string as! NSString).size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: labelFontSize)])
    upperLabelTextSize = (upperLabel.string as! NSString).size(withAttributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: labelFontSize)])
  }
  
  ///Updates the labels positions above the knobs.
  open func updateLabelPositions() {
    let minDistanceBetweenLabels: CGFloat = 8.0
    
    let lowerKnobCenter = centerOfRect(rect: lowerKnob.frame)
    let upperKnobCenter = centerOfRect(rect: upperKnob.frame)
    
    var newLowerLabelCenter = CGPoint(x: lowerKnobCenter.x, y: lowerKnob.frame.origin.y - (lowerLabel.frame.size.height / 2))
    var newUpperLabelCenter = CGPoint(x: upperKnobCenter.x, y: upperKnob.frame.origin.y - (upperLabel.frame.size.height / 2))
    
    lowerLabel.frame = CGRect(x: 0, y: 0, width: lowerLabelTextSize.width, height: lowerLabelTextSize.height)
    upperLabel.frame = CGRect(x: 0, y: 0, width: upperLabelTextSize.width, height: upperLabelTextSize.height)
    
    let rightMostXInLowerLabel = newLowerLabelCenter.x + lowerLabelTextSize.width / 2
    let leftMostXInUpperLabel = newUpperLabelCenter.x - upperLabelTextSize.width / 2
    let spacingBetweenLabels = leftMostXInUpperLabel - rightMostXInLowerLabel
    
    if spacingBetweenLabels < minDistanceBetweenLabels {
      let increaseAmount = minDistanceBetweenLabels - spacingBetweenLabels
      newLowerLabelCenter = CGPoint(x: lowerKnobCenter.x - increaseAmount / 2, y: newLowerLabelCenter.y)
      newUpperLabelCenter = CGPoint(x: upperKnobCenter.x + increaseAmount / 2, y: newUpperLabelCenter.y)
    }
    
    lowerLabel.position = newLowerLabelCenter
    upperLabel.position = newUpperLabelCenter
  }
  
  // MARK: Touch Tracking
  
    private func highlightKnob(_ knob: RangeSliderKnob, knobPosition: Knob) {
        knob.highlighted = true
        previouslySelectedKnob = knobPosition
        animateKnob(knob: knob, selected: true)
    }
    
  /**
   Triggers on touch of the `RangeSlider` and checks whether either of the slider buttons have been touched and sets their `highlighted` property to true.
   
   - returns: A bool indicating if either of the slider buttons were inside of the `UITouch`.
 */
  override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    previousLocation = touch.location(in: self)
    
    if lowerKnob.frame.contains(previousLocation) && upperKnob.frame.contains(previousLocation) {
        
        if knobsAreClose {
            let knobToHighlight = knobsAreCloserToMinimum ? upperKnob : lowerKnob
            let knobPosiition = knobsAreCloserToMinimum ? Knob.Upper : Knob.Lower
            highlightKnob(knobToHighlight, knobPosition: knobPosiition)
            return true
        }
        
        let knobToHighlight = previouslySelectedKnob == Knob.Lower ? lowerKnob : upperKnob
        let knobPosiition = previouslySelectedKnob == Knob.Lower ? Knob.Lower : Knob.Upper
        highlightKnob(knobToHighlight, knobPosition: knobPosiition)
        return true
    }
    
    if lowerKnob.frame.contains(previousLocation) {
        highlightKnob(lowerKnob, knobPosition: Knob.Lower)
        return true
    }
    
    if upperKnob.frame.contains(previousLocation) {
        highlightKnob(upperKnob, knobPosition: Knob.Upper)
        return true
    }
    
    if (dragTrack) {
      upperKnob.highlighted = true
      lowerKnob.highlighted = true
      animateKnob(knob: lowerKnob, selected: true)
      animateKnob(knob: upperKnob, selected: true)
      return true
    }
    
    return false
  }
  
  /**
   Triggers on a continued touch of the `RangeSlider` and updates the value corresponding with the new button location.
   
   - returns: A bool indicating success.
   */
  override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let location = touch.location(in: self)
    
    let deltaLocation = Double(location.x - previousLocation.x)
    var deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - KnobSize)
    
    if abs(deltaValue) < stepValue {
      return true
    }
    
    if stepValue != 0 {
      deltaValue = deltaValue < 0 ? -stepValue : stepValue
    }
    
    previousLocation = location
    
    if lowerKnob.highlighted && upperKnob.highlighted {
      let gap = upperValue - lowerValue
      if (deltaValue > 0) {
        let newUpperValue = upperValue + deltaValue
        upperValue = boundValue(newUpperValue, toLowerValue: (lowerValue + max(minimumDistance, gap)), upperValue: maximumValue)
        let newLowerValue = lowerValue + deltaValue
        lowerValue = boundValue(newLowerValue, toLowerValue: minimumValue, upperValue: (upperValue - max(minimumDistance, gap)))
      } else {
        let newLowerValue = lowerValue + deltaValue
        lowerValue = boundValue(newLowerValue, toLowerValue: minimumValue, upperValue: (upperValue - max(minimumDistance, gap)))
        let newUpperValue = upperValue + deltaValue
        upperValue = boundValue(newUpperValue, toLowerValue: (lowerValue + max(minimumDistance, gap)), upperValue: maximumValue)
      }
    }
    else if lowerKnob.highlighted {
      let newLowerValue = lowerValue + deltaValue
      lowerValue = boundValue(newLowerValue, toLowerValue: minimumValue, upperValue: (upperValue - minimumDistance))
    } else if upperKnob.highlighted {
      let newUpperValue = upperValue + deltaValue
      upperValue = boundValue(newUpperValue, toLowerValue: (lowerValue + minimumDistance), upperValue: maximumValue)
    }
    
    sendActions(for: .valueChanged)
        
    return true
  }
  
  /**
   Triggers on the end of touch of the `RangeSlider` and sets the button layers `highlighted` property to `false`.
   */
  override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    if lowerKnob.highlighted {
      lowerKnob.highlighted = false
      animateKnob(knob: lowerKnob, selected: false)
    }
    
    if upperKnob.highlighted {
      upperKnob.highlighted = false
      animateKnob(knob: upperKnob, selected: false)
    }
  }
  
  // MARK: Animations
  
  ///Animates the knobs to grow in size depending on the value of `selectedKnobDiameterMultiplier`
  func animateKnob(knob: RangeSliderKnob, selected:Bool) {
    CATransaction.begin()
    CATransaction.setAnimationDuration(0.3)
    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
    
    knob.transform = selected ? CATransform3DMakeScale(selectedKnobDiameterMultiplier, selectedKnobDiameterMultiplier, 1) : CATransform3DIdentity
    
    updateLabelPositions()
    
    CATransaction.setCompletionBlock({
    })
    CATransaction.commit()
  }
  
  // MARK: Helper Functions
  
  /**
   Returns the position of the Knob to be placed on the slider given the value it should be on the slider
   */
  func positionForValue(_ value: Double) -> CGPoint {
    if maximumValue == minimumValue {
      return CGPoint(x: 0, y: 0)
    }
    
    let percentage = percentageForValue(value)
    
    let knobDeltaX: CGFloat = (KnobSize / 2) - RangeSliderKnob.KnobDelta
    let knobDeltaWidth:CGFloat = -(KnobSize - (RangeSliderKnob.KnobDelta * 2))
    
    let xPosition = (bounds.width + knobDeltaWidth) * percentage
    
    let yPosition = track.frame.midY
    
    return CGPoint(x: xPosition + knobDeltaX, y: yPosition)
  }
  
  func percentageForValue(_ value: Double) -> CGFloat {
    if minimumValue == maximumValue {
      return 0
    }
    
    let maxMinDiff = maximumValue - minimumValue
    let valueSubtracted = value - minimumValue
    
    return CGFloat(valueSubtracted / maxMinDiff)
  }
  
  func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
    return min(max(value, lowerValue), upperValue)
  }
  
  func centerOfRect(rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.midX, y: rect.midY)
  }
}

































