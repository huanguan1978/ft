## 1.0.7

- Add `parseMimeTypes` and `resolvePath` utility functions.
- Add `--mime_file` CLI option to load MIME types from external files.

## 1.0.6

- fix(Shell): resolve progress bar hang after `cd` command.
- refactor(crc): split into independent CRC64 and CRC32 methods.

## 1.0.5

- Shell: fixed, `Process.runSync` passes argument block, e.g. (rsync -e "..."): 
```bash
rsync -avz -e "ssh -i ~/FileShows/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" 
```
- Docs: more configurations, examples, and screenshots.

## 1.0.4

- Feat: Introduced MIME-type filtering (`--mime_includes`, `--mime_excludes`) and custom MIME mapping (`--mime_overrides`).
- Docs: New guide `T5-MIMETYPE-Filtering` added to the documentation with detailed usage and examples.


## 1.0.3

- Shell: fixed, Unlike shell execution, `Process.runSync` passes arguments literally, meaning quotes are not automatically stripped.
- Shell: Added '--keep_quotes', keep quotes in script arguments, defauts to off.

## 1.0.2

- Search: Added '--onlygroups' and '--linenum' toggles for regex group extraction and optional line numbering.
- Search: fixed FormatException (unexpected extension byte).

## 1.0.1

- Dart/Flutter: dart pub global activate --executable=ft filetools

## 1.0.0

- Initial version.
