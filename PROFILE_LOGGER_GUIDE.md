# Profile Screen Logger Guide

## Overview

A comprehensive logging system has been added to the `ProfileScreen` to track loading performance, debug issues, and monitor the initialization lifecycle.

## Logger Features

### 📊 Performance Tracking
- **Automatic Stopwatch**: Tracks elapsed time from screen initialization
- **Millisecond Precision**: All events logged with exact timing
- **Cumulative Timing**: Shows total time since screen started loading

### 🎨 Visual Indicators
- ✅ **Success** - Green checkmark for successful operations
- ❌ **Error** - Red X for failures with stack traces
- ⚠️ **Warning** - Yellow warning for non-critical issues
- 🔵 **Event** - Blue dot for general events

### 📍 Tag System
All logs are prefixed with `🔵 [ProfileScreen]` for easy filtering in console

## Logger Methods

```dart
// Start the timer (called in initState)
ProfileLogger.startTimer();

// Log a general event
ProfileLogger.logEvent('Event name');
ProfileLogger.logEvent('Event name', details: 'Additional info');

// Log success
ProfileLogger.logSuccess('Operation completed');
ProfileLogger.logSuccess('Profile loaded', details: 'User: John Doe');

// Log warning
ProfileLogger.logWarning('Widget not mounted');

// Log error with stack trace
ProfileLogger.logError('Failed to load', stackTrace: stackTrace);
```

## Log Output Example

```
🔵 [ProfileScreen] [0 ms] initState() called
🔵 [ProfileScreen] [5 ms] Initializing glow animation
🔵 [ProfileScreen] ✅ [12 ms] Glow animation initialized
🔵 [ProfileScreen] [15 ms] Initializing staggered animations
🔵 [ProfileScreen] ✅ [25 ms] Staggered animations initialized
🔵 [ProfileScreen] [28 ms] Setting up scroll listener
🔵 [ProfileScreen] ✅ [32 ms] Scroll listener configured
🔵 [ProfileScreen] [35 ms] Scheduling profile load
🔵 [ProfileScreen] [45 ms] User authenticated - UID: abc123xyz
🔵 [ProfileScreen] [48 ms] _loadUserProfile() started
🔵 [ProfileScreen] [50 ms] Setting loading state to true
🔵 [ProfileScreen] [52 ms] Fetching localization strings
🔵 [ProfileScreen] ✅ [58 ms] Localization strings loaded
🔵 [ProfileScreen] [60 ms] Fetching user profile from Firebase
🔵 [ProfileScreen] ✅ [245 ms] User profile fetched - Time: 185ms
🔵 [ProfileScreen] [248 ms] Profile data received - User: John Doe, Role: client
🔵 [ProfileScreen] [250 ms] Updating state with profile data
🔵 [ProfileScreen] ✅ [255 ms] Profile state updated
🔵 [ProfileScreen] [258 ms] Starting staggered entry animation
🔵 [ProfileScreen] ✅ [260 ms] Animation started
🔵 [ProfileScreen] ✅ [262 ms] _loadUserProfile() completed
```

## Logged Events

### Initialization Phase
1. `initState() called` - Screen initialization starts
2. `Initializing glow animation` - Avatar glow effect setup
3. `Glow animation initialized` - Glow effect ready
4. `Initializing staggered animations` - Content animations setup
5. `Staggered animations initialized` - Animations ready
6. `Setting up scroll listener` - Header collapse listener setup
7. `Scroll listener configured` - Scroll listener ready
8. `Scheduling profile load` - Profile fetch scheduled

### Authentication Phase
1. `User authenticated` - User UID logged
2. `No authenticated user found` - Redirect to login

### Profile Loading Phase
1. `_loadUserProfile() started` - Profile fetch begins
2. `Setting loading state to true` - Loading indicator shown
3. `Fetching localization strings` - i18n strings loading
4. `Localization strings loaded` - i18n ready
5. `Fetching user profile from Firebase` - Firestore query starts
6. `User profile fetched` - Firestore query completes with timing
7. `Profile data received` - User data parsed
8. `Updating state with profile data` - setState called
9. `Profile state updated` - State update complete
10. `Starting staggered entry animation` - Content animation starts
11. `Animation started` - Animation running
12. `_loadUserProfile() completed` - Profile load finished

## Performance Metrics to Monitor

### Key Timings
- **Total Init Time**: Time from `initState()` to `_loadUserProfile() completed`
- **Firebase Fetch Time**: Time for `getCurrentUserProfile()` call
- **Animation Setup Time**: Time to initialize all animations
- **State Update Time**: Time for setState to complete

### Example Performance Baseline
```
Animation Setup:     ~30 ms
Localization Load:   ~6 ms
Firebase Fetch:      ~150-300 ms (depends on network)
State Update:        ~5 ms
Total Load Time:     ~200-350 ms
```

## Debugging with Logs

### Finding Performance Bottlenecks
1. Look for large gaps between timestamps
2. Firebase fetch time > 500ms? Check network/Firestore indexes
3. Animation setup > 50ms? Check animation complexity

### Troubleshooting Issues

**Profile not loading?**
- Check for "No authenticated user found" warning
- Look for errors in Firebase fetch phase

**Animations not playing?**
- Verify "Staggered animations initialized" logged
- Check "Animation started" was called

**Slow loading?**
- Compare Firebase fetch time with baseline
- Check if multiple profile loads happening (duplicate logs)

## Filtering Logs in Console

### View only ProfileScreen logs
```bash
# In Flutter DevTools console
ProfileScreen
```

### View only errors
```bash
# In Flutter DevTools console
ProfileScreen.*❌
```

### View only timing info
```bash
# In Flutter DevTools console
ProfileScreen.*\[\d+ ms\]
```

## Integration with Analytics

The logger can be extended to send metrics to Firebase Analytics:

```dart
// Example: Send timing to Firebase
FirebaseAnalytics.instance.logEvent(
  name: 'profile_load_time',
  parameters: {
    'duration_ms': loadTime,
    'user_role': userData.role,
  },
);
```

## Best Practices

1. **Always check logs first** when debugging profile issues
2. **Monitor Firebase fetch time** - should be < 500ms
3. **Use details parameter** for contextual information
4. **Check for unmounted warnings** - indicates lifecycle issues
5. **Compare timings** across different devices/networks

## Future Enhancements

- [ ] Add log level filtering (DEBUG, INFO, WARNING, ERROR)
- [ ] Export logs to file for analysis
- [ ] Add Firebase Analytics integration
- [ ] Create performance dashboard
- [ ] Add memory usage tracking
- [ ] Implement log rotation

## Files Modified

- ✅ `lib/screens/profile_screen.dart` - Added ProfileLogger class and logging calls

