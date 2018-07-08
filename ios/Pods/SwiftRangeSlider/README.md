# SwiftRangeSlider
![CocoaPods](https://img.shields.io/cocoapods/v/SwiftRangeSlider.svg)
![CocoaPods](https://img.shields.io/cocoapods/l/SwiftRangeSlider.svg)
![CocoaPods](https://img.shields.io/cocoapods/p/SwiftRangeSlider.svg)

This is a swift implementation of custom UIControl that allows users to select a range of values on a slider bar with 2 knobs.

## Requirements

- iOS 8.0+
- Xcode 8+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build SwiftRangeSlider.

To integrate SwiftRangeSlider into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, ‘8.0’
use_frameworks!
target '[your_app_name]' do
  pod ‘SwiftRangeSlider’
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage
```swift
import SwiftRangeSlider
```

### With Storyboards

To use SwiftRangeSlider on a storyboard, add a UIView to your view controller and set its class to RangeSlider. The Range Slider defaults to an iOS-esque style of slider, but it can be modified to look lots of different ways! There is even scaling on touch and labels, so be sure to experiment until you find exactly what you like!

![SRS With Storyboards 1](http://imgur.com/C69FAOO.png)
![SRS With Storyboards 2](http://i.imgur.com/HSVrFKU.png)

Most of the customization parameters can be changed through IBDesignable and IBInspectable and should be reflected on the storyboard!

![SRS With Storyboards 3](http://imgur.com/sog8OMz.png)

To reference the `RangeSlider` on your storyboard in your view controller's file, create an `@IBOutlet` connection of type `RangeSlider`:

```swift
@IBOutlet weak var rangeSlider: RangeSlider!
```

### Programmatically

```swift
let rangeSlider:RangeSlider = RangeSlider()
```
