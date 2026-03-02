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
