/*
 * Copyright 2011-2012 StackThread Software Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class STHorizontalPicker;

//================================
// Delegate protocol
//================================
@protocol STHorizontalPickerDelegate <NSObject>

@optional
- (CGFloat)minimumValueForPickerView:(STHorizontalPicker *)picker;
- (CGFloat)maximumValueForPickerView:(STHorizontalPicker *)picker;
- (NSUInteger)stepCountForPickerView:(STHorizontalPicker *)picker;

@required
- (void)pickerView:(STHorizontalPicker *)picker didSelectValue:(CGFloat)value;

@end

//================================
// UIColor category
//================================
@interface UIColor (STColorComponents)
- (CGFloat)red;
- (CGFloat)green;
- (CGFloat)blue;
- (CGFloat)alpha;
@end


//================================
// STHorizontalPicker interface
//================================
@interface STHorizontalPicker : UIView <UIScrollViewDelegate> {
    CGFloat value;
    
    NSUInteger steps;
    CGFloat minimumValue;
    CGFloat maximumValue;
    
    id delegate;
    
    UIColor *borderColor;
    CGFloat fontSize;
    
    @private
    CGFloat scale; // Drawing scale    
}

@property (nonatomic, retain) NSString *name;

- (void)snapToMarkerAnimated:(BOOL)animated;

- (CGFloat)minimumValue;
- (void)setMinimumValue:(CGFloat)newMin;

- (CGFloat)maximumValue;
- (void)setMaximumValue:(CGFloat)newMax;

- (NSUInteger)steps;
- (void)setSteps:(NSUInteger)newSteps;

- (CGFloat)value;
- (void)setValue:(CGFloat)newValue;

- (UIColor *)borderColor;
- (void)setBorderColor:(UIColor *)newBorderColor;

- (CGFloat)fontSize;
- (void)setFontSize:(CGFloat)newFontSize;

- (id)delegate;
- (void)setDelegate:(id<STHorizontalPickerDelegate>)newDelegate;
- (void)callDelegateWithNewValueFromOffset:(CGFloat)offset;

@end



//================================
// STPointerLayerDelegate interface
//================================
@interface STPointerLayerDelegate : NSObject {}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context;

@end