bazel build //sample
IF %ERRORLEVEL% NEQ 0 EXIT 1

7z a qt_windows.zip bazel-aabtop_rules_qt/external/aabtop_rules_qt/* -r
IF %ERRORLEVEL% NEQ 0 EXIT 1
