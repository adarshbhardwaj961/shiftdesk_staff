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
| Same date and time repeated throughout the open-shift list | The seeded schedule reused a 16-hour modulo cycle, assigning identical timestamps to different shift IDs | Generate a distinct 15-minute start slot for each seeded shift on a day and verify timestamp uniqueness |
| Items can be skipped or repeated after a booking changes page membership | Offset cursors assume the filtered list stays fixed, but claiming/cancelling changes which shifts are open between requests | Anchor each cursor to the last delivered shift in the stable date/department ordering; deduplicate in the controller as a second safeguard |
| A filter change can show results from an old query | The cursor and in-flight request were not tied to the active filter values | Clear pagination on filter changes, restart at page one, and ignore responses from superseded requests |
| A past or already-started shift can still be claimed | Availability filtering and the claim rule did not consistently check the current time | Exclude started shifts from open results and reject them in the shared claim rule, which is also enforced by the fake API |
| Licence rejected on its printed expiry date | A date-only expiry value was compared with the shift's time-of-day | Compare UTC calendar dates so the licence remains valid through its expiry date |

The fixed reference files are under `part2/debug/`. They are based on the snippets in the brief and may need import/model-name adaptation to the actual supplied starter files.
