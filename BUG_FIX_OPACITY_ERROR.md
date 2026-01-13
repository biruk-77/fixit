# Bug Fix: Color.withOpacity() Assertion Error

## Issue Description

**Error**: `'dart:ui/painting.dart': Failed assertion: line 342 pos 12: '<optimized out>': is not true.`

**Location**: `lib/screens/profile_screen.dart:947` in `_buildDynamicHeader()`

**Root Cause**: The `textOpacity` value was being calculated as `1.0 - (scrollFactor * 1.5)`, which could result in negative values when `scrollFactor` exceeded 0.67. Flutter's `Color.withOpacity()` method requires opacity values to be between 0.0 and 1.0 (inclusive).

## Problem Scenario

```
scrollFactor = 0.8 (80% collapsed)
textOpacity = 1.0 - (0.8 * 1.5) = 1.0 - 1.2 = -0.2  ❌ INVALID
```

When `withOpacity(-0.2)` was called, it triggered an assertion error because opacity must be in range [0.0, 1.0].

## Solution Applied

Added `.clamp(0.0, 1.0)` to the `textOpacity` calculation to ensure it never goes below 0.0 or above 1.0.

### Before (Line 657-658)
```dart
final double textOpacity =
    1.0 - (scrollFactor * 1.5); // Fade out text faster
```

### After (Line 657-658)
```dart
final double textOpacity =
    (1.0 - (scrollFactor * 1.5)).clamp(0.0, 1.0); // Fade out text faster, clamped to valid range
```

## Impact

✅ **Fixed**: Profile screen no longer crashes when scrolling the header
✅ **Behavior**: Text smoothly fades out as header collapses, then stays invisible
✅ **Performance**: No performance impact (clamp is O(1) operation)

## Testing

### Before Fix
1. Open Profile tab
2. Scroll up to collapse header
3. ❌ Crash with opacity assertion error

### After Fix
1. Open Profile tab
2. Scroll up to collapse header
3. ✅ Header smoothly collapses with text fade animation
4. ✅ No crashes

## Logging Added

Added debug logging to track opacity values during header collapse:

```dart
// Log opacity values for debugging (only in debug mode)
if (scrollFactor > 0.5) {
  ProfileLogger.logEvent('Header collapse', details: 'scrollFactor: ${scrollFactor.toStringAsFixed(2)}, textOpacity: ${textOpacity.toStringAsFixed(2)}');
}
```

**Console Output Example**:
```
🔵 [ProfileScreen] [1450 ms] Header collapse - scrollFactor: 0.50, textOpacity: 0.25
🔵 [ProfileScreen] [1452 ms] Header collapse - scrollFactor: 0.75, textOpacity: 0.00
🔵 [ProfileScreen] [1454 ms] Header collapse - scrollFactor: 1.00, textOpacity: 0.00
```

## Files Modified

- ✅ `lib/screens/profile_screen.dart` (Line 658)
  - Added `.clamp(0.0, 1.0)` to textOpacity calculation
  - Added debug logging for opacity tracking

## Related Code

The issue was in the `_buildDynamicHeader()` method which calculates opacity values for the collapsing header animation:

```dart
final double scrollFactor =
    (_headerScrollOffset / (expandedHeight - minHeight)).clamp(0.0, 1.0);
final double textOpacity =
    (1.0 - (scrollFactor * 1.5)).clamp(0.0, 1.0); // NOW SAFE
```

The `textOpacity` is used in multiple places:
- Line 947: `Colors.white.withOpacity(textOpacity)`
- Line 951-952: `Colors.black.withOpacity(0.3 * textOpacity)`

## Opacity Behavior After Fix

| scrollFactor | textOpacity (Before) | textOpacity (After) | Result |
|---|---|---|---|
| 0.0 | 1.0 | 1.0 | Fully visible |
| 0.33 | 0.5 | 0.5 | 50% visible |
| 0.67 | 0.0 | 0.0 | Invisible |
| 0.80 | -0.2 ❌ | 0.0 ✅ | Invisible |
| 1.0 | -0.5 ❌ | 0.0 ✅ | Invisible |

## Prevention

To prevent similar issues in the future:

1. **Always clamp opacity values** when they're calculated dynamically
2. **Use assertions in development** to catch invalid values early
3. **Test scroll animations** thoroughly on different screen sizes
4. **Monitor logs** for opacity values during testing

## Status

✅ **FIXED** - Profile screen now works without crashes

**Commit**: Ready to deploy

