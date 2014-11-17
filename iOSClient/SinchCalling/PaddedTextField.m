
#import "PaddedTextField.h"

@implementation PaddedTextField

- (UIEdgeInsets)paddingInsets {
  return UIEdgeInsetsMake(5, 10, 5, 10);
}

- (CGRect)textRectForBounds:(CGRect)bounds {
  return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, [self paddingInsets])];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, [self paddingInsets])];
}

@end
