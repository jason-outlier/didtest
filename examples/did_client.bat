@echo off
echo DID System Test Client
echo.
echo Usage: did_client.bat <host> <port>
echo Example: did_client.bat 192.168.1.100 4040
echo.
if "%1"=="" (
    echo Please provide host and port arguments
    pause
    exit /b 1
)
if "%2"=="" (
    echo Please provide port argument
    pause
    exit /b 1
)

echo Connecting to DID system at %1:%2
echo.
echo Available commands:
echo 1. *1W0000* - Add order 0000 to waiting list
echo 2. *1A0000* - Add order 0000 to completed list (removes from waiting if present)
echo 3. *1D0000* - Remove order 0000 from both lists
echo 4. *1C0000* - Clear all orders
echo 5. quit - Exit client
echo.
echo Format: *1W0000* where * = delimiter, W=wait, A=complete, D=delete, C=clear all, last 4 digits=order number
echo.

:loop
set /p command="Enter command: "
if /i "%command%"=="quit" goto :end
if "%command:~0,1%"=="*" (
    if "%command:~1,1%"=="1" (
        if "%command:~2,1%"=="W" (
            echo Sending: %command%
            echo %command% | nc %1 %2
            goto :loop
        )
        if "%command:~2,1%"=="A" (
            echo Sending: %command%
            echo %command% | nc %1 %2
            goto :loop
        )
        if "%command:~2,1%"=="D" (
            echo Sending: %command%
            echo %command% | nc %1 %2
            goto :loop
        )
        if "%command:~2,1%"=="C" (
            echo Sending: %command%
            echo %command% | nc %1 %2
            goto :loop
        )
    )
)
echo Invalid command. Use *1W0000* (wait), *1A0000* (complete), *1D0000* (delete), *1C0000* (clear all) or quit
goto :loop

:end
echo Exiting...
pause
