SET BAZEL_OUT_DIR=%~f1
SET OUT_DIR=%~f2
SET SRC_DIR=%0\..\..\..
SET BUILD_CONFIG=opt

echo "In container, building..."

cd %SRC_DIR%

bazel --output_user_root=%BAZEL_OUT_DIR% build //sample -c %BUILD_CONFIG% --symlink_prefix=/ --verbose_failures
IF %ERRORLEVEL% NEQ 0 EXIT 1

for /f "usebackq tokens=*" %%a in (`bazel --output_user_root=%BAZEL_OUT_DIR% info execution_root -c %BUILD_CONFIG%`) do (
  7z a %OUT_DIR%/qt_windows.zip %%a\external\aabtop_qt_build\* -r
  IF %ERRORLEVEL% NEQ 0 EXIT 1
)
