// InputMethodKit's document access selectors. Clients that do not implement
// them simply use local Rime candidates. No Accessibility permission is needed.
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
@protocol JevDocumentAccess
- (NSRange)selectedRange;
- (NSRange)markedRange;
- (NSAttributedString*)attributedSubstringFromRange:(NSRange)range;
@end

NS_INLINE NSDictionary<NSString*, NSString*>* _Nullable JevReadContext(id _Nullable object) {
  if (!object || IsSecureEventInputEnabled() ||
      ![object respondsToSelector:@selector(selectedRange)] ||
      ![object respondsToSelector:@selector(markedRange)] ||
      ![object respondsToSelector:@selector(attributedSubstringFromRange:)]) return nil;
  id<JevDocumentAccess> client = object;
  @try {
    NSRange selection = [client selectedRange];
    NSRange marked = [client markedRange];
    if (selection.location == NSNotFound) return nil;
    NSRange anchor = marked.location == NSNotFound ? selection : marked;
    if (anchor.location > NSUIntegerMax - anchor.length) return nil;
    if (marked.location != NSNotFound && (selection.location < marked.location ||
        NSMaxRange(selection) > NSMaxRange(marked))) return nil;
    NSUInteger length = MIN(anchor.location, 384);
    NSString* before = length ? [client attributedSubstringFromRange:
        NSMakeRange(anchor.location - length, length)].string : @"";
    if (!before) return nil;
    NSString* after = [client attributedSubstringFromRange:
        NSMakeRange(NSMaxRange(anchor), 128)].string ?: @"";
    return @{@"before": before, @"after": after};
  } @catch (NSException* exception) {
    return nil;
  }
}
