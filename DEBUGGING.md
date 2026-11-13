# Part 2 debugging notes

| Symptom | Root cause | Fix |
|---|---|---|
| Duplicate shifts while scrolling | Pagination can be triggered repeatedly and appended without checking IDs | Guard concurrent loads and deduplicate by shift ID |
| Back-to-back shifts rejected | Inclusive overlap comparison treats equal endpoints as overlap | Use half-open interval overlap: start A < end B and start B < end A |
| Crash when navigating back during load | Async completion calls setState after widget disposal | Check `mounted` after awaits and before state updates; dispose controller/listener |
| Claim button remains stale | Local mutable shift is changed without notifying the screen/repository state | Refresh/notify shared state after successful claim and handle API errors |
| Scrolling gets slower over time | Full list is loaded and rendered eagerly; listener added on every build | Use paginated ListView.builder and register one scroll listener in initState |
| ER list takes too long | API client fetches every page before returning | Return one page and let the UI request more as needed |
| Department sometimes returns no results | Query string is manually concatenated and values are not URI-encoded; request construction is fragile | Use `Uri.replace(queryParameters: ...)` and verify filter/cursor parameters |
| Password exposed in local preferences | Password stored in SharedPreferences | Never store password; store token in secure storage |
| Token appears in logs | Request logs print authorization token | Remove sensitive logs and never log secrets |
| Claim capacity/weekly-hours edge cases | Rules use incorrect capacity and interval/week calculations | Use `filled >= slots`, half-open intervals and Monday-to-Monday weekly boundaries |

The fixed reference files are under `part2/debug/`. They are based on the snippets in the brief and may need import/model-name adaptation to the actual supplied starter files.
