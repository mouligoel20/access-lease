@echo off
setlocal
cd /d "%~dp0backend"
if exist ".venv\Scripts\python.exe" goto install
if exist "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" (
  "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -m venv .venv
) else (
  py -3.12 -m venv .venv
)
if errorlevel 1 goto failed
:install
".venv\Scripts\python.exe" -m pip install -r requirements.txt --disable-pip-version-check
if errorlevel 1 goto failed
echo Open http://127.0.0.1:8000/ after Application startup complete appears.
echo Keep this window open. Press Ctrl+C to stop the server.
".venv\Scripts\python.exe" -m uvicorn main:app --host 127.0.0.1 --port 8000
goto end
:failed
echo Setup failed. Check your internet connection and Python 3.12 installation.
:end
pause
