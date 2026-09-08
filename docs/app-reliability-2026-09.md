# App reliability completion — September 7, 2026

> Part of the [complete v2.6 release dossier](releases/v2.6/README.md). Test counts below describe this milestone; the final implementation total is **265**, recorded in the [validation ledger](releases/v2.6/Validation.md). [Live ASC status](releases/v2.6/ASCStatus.md) is tracked separately.


## Changes

- Chat switching cancels the outgoing response, flushes its buffered text into the owning conversation, and invalidates delayed callbacks. Flushes resolve message UUIDs instead of trusting an old array index. Deleting an active stream cannot restore a deleted conversation through a pending save.
- Conversation saves coalesce on a 750 ms checkpoint, serialize and write on a serial background queue, and flush at response completion and app backgrounding. Unchanged message images reuse their PNG encoding. Save failures surface without recursively appending more unsavable messages. Existing JSON files remain compatible.
- The app root owns the one chat controller; ContentView reads it from the environment.
- Vector-store uploads wait for completed indexing. Server failures, ongoing indexing, and ready files remain distinct. Results stay visible after partial success, polling has a 90 second deadline, Stop cancels local waiting, and Check Indexing Again resumes status checks without uploading another copy. Server-side indexing can continue after local cancellation.
- Batch results and error files download directly to disk and open the system save/share sheet. Available partial outputs can be exported regardless of final job status. Download failures are surfaced and full result bytes are retained.
- Fine-tuning accepts reviewed UTF-8 JSONL datasets with at least ten text-only supervised examples, validates hyperparameters, and snapshots submission settings. Current-chat export is a draft and excludes app system/status messages. The screen explains restricted fine-tuning availability and links to OpenAI's current guidance. Model choices use documented GPT-4.1 snapshots; account eligibility remains server-authoritative.
- Vector-store files, Batch jobs, and fine-tuning jobs follow cursor pagination, deduplicate overlapping pages, and reject missing/repeating cursors or excessive pages instead of silently returning an incomplete collection. Notion chat search accepts page_size and start_cursor; compacting a server page preserves all results and its continuation cursor.
- ChatViewModelLifecycleTests is included in the test target. Its stale protocol mocks and async assertions are repaired. Restoring it exposed a non-streaming function-batch race: expected calls are now declared before execution, and only one complete batch is submitted. Follow-ups no longer wait for unused reasoning payloads.

## Verification

- 265 unit/integration tests passed, with zero failures: the previous 238 tests, 13 restored lifecycle tests, and 14 new regressions.
- Regressions exercise chat switching, changed message indices, deletion persistence, coalesced image saves, image-cache invalidation, complete Batch error-file bytes, multi-page lists, repeating cursors, indexing completion/failure/deadline, dataset validation, and Notion page preservation.
- Simulator app build, install, launch, and runtime UI inspection passed. Fine-tuning's availability notice, reviewed-dataset import, chat draft export, and disabled submission before dataset selection were visually checked.
- Signed iPhone build succeeded; installed and launched on Gunnar's Hand Extension (iPhone 16 Pro Max). The running app process was confirmed.
- Four existing device conversation files were copied and hashed before installation and after relaunch. All four SHA-256 hashes and byte counts matched.
- git diff --check passed.

Validation did not create a paid Batch or fine-tuning job. Network boundaries for these revised flows are covered with deterministic transport/polling fixtures; actual job admission and indexing duration depend on the service and account.

## References

- [Supervised fine-tuning availability and dataset requirements](https://developers.openai.com/api/docs/guides/supervised-fine-tuning)
- [Batch result and error files](https://developers.openai.com/api/docs/guides/batch)
- [Vector-store file indexing status](https://developers.openai.com/api/reference/cli/resources/vector_stores/subresources/files/methods/retrieve)
