# ProfileLogger Quick Reference

## One-Liner Usage

```dart
// In ProfileScreen
ProfileLogger.startTimer();                    // Start in initState()
ProfileLogger.logEvent('Event name');          // Log event
ProfileLogger.logEvent('Event', details: 'info'); // Log with details
ProfileLogger.logSuccess('Done');              // Log success
ProfileLogger.logSuccess('Done', details: 'info'); // Success with details
ProfileLogger.logWarning('Warning');           // Log warning
ProfileLogger.logError('Error', stackTrace: st); // Log error
```

## Output Format

```
🔵 [ProfileScreen] [elapsed ms] message
✅ [elapsed ms] message - details
❌ [elapsed ms] ERROR: message
⚠️ [elapsed ms] message
```

## Key Events to Monitor

| Event | What It Means | Normal Time |
|-------|--------------|------------|
| `initState() called` | Screen starting | 0 ms |
| `Glow animation initialized` | Avatar animation ready | ~12 ms |
| `Staggered animations initialized` | Content animations ready | ~25 ms |
| `Scroll listener configured` | Header collapse ready | ~32 ms |
| `User authenticated` | User logged in | ~45 ms |
| `Fetching user profile from Firebase` | Database query starting | ~60 ms |
| `User profile fetched` | Database query done | 150-300 ms |
| `Profile state updated` | UI updated with data | ~255 ms |
| `Animation started` | Content fade-in starting | ~260 ms |
| `_loadUserProfile() completed` | All done | ~262 ms |

## Performance Targets

```
✅ Good:     < 300 ms total load time
⚠️ Warning:  300-500 ms (acceptable)
❌ Bad:      > 500 ms (needs optimization)
```

## Common Issues & Solutions

| Issue | Log Sign | Fix |
|-------|----------|-----|
| Slow Firebase | `User profile fetched - Time: 500+ms` | Check network, add indexes |
| Not loading | `No authenticated user found` | Check auth state |
| Animations stuck | No `Animation started` | Check animation controller |
| Duplicate loads | Multiple `_loadUserProfile()` | Check for duplicate calls |

## Copy-Paste Template

For new logging in ProfileScreen:

```dart
ProfileLogger.logEvent('Starting operation');
try {
  // Do something
  ProfileLogger.logSuccess('Operation done');
} catch (e, st) {
  ProfileLogger.logError('Operation failed', stackTrace: st);
}
```

## View Logs in DevTools

1. Open Flutter DevTools
2. Go to "Logging" tab
3. Filter by: `ProfileScreen`
4. Watch timestamps for performance

## Export Logs

```bash
# Copy console output and save to file
flutter run 2>&1 | grep "ProfileScreen" > profile_logs.txt
```

