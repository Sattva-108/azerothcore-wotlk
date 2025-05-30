@echo off
chcp 65001 > nul
echo 🔧 pfQuest Extractor Auto-Fix Tool
echo ==================================

if "%1"=="" (
    echo ❌ Использование: fix_extractor.bat [FIELD_NAME]
    echo.
    echo 💡 Примеры:
    echo    fix_extractor.bat entry      ^(заменит creature.id на creature.entry^)
    echo    fix_extractor.bat id1        ^(заменит creature.id на creature.id1^)
    echo    fix_extractor.bat guid       ^(заменит creature.id на creature.guid^)
    echo.
    echo 🔍 Сначала запусти sql_diagnostic.bat чтобы найти правильное поле!
    pause
    exit /b 1
)

set FIELD_NAME=%1
set EXTRACTOR_FILE=extractor.lua
set BACKUP_FILE=extractor_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.lua

REM Убираем двоеточия из времени для Windows
set BACKUP_FILE=%BACKUP_FILE::=%

echo 📁 Работаем с файлом: %EXTRACTOR_FILE%
echo 🎯 Заменяем creature.id на creature.%FIELD_NAME%
echo.

REM Проверяем существование файла
if not exist "%EXTRACTOR_FILE%" (
    echo ❌ Файл %EXTRACTOR_FILE% не найден!
    echo 💡 Убедись что запускаешь из папки pfQuest-master\toolbox\
    pause
    exit /b 1
)

REM Создаем бэкап
echo 💾 Создаем бэкап: %BACKUP_FILE%
copy "%EXTRACTOR_FILE%" "%BACKUP_FILE%" > nul

if %ERRORLEVEL% neq 0 (
    echo ❌ Не удалось создать бэкап!
    pause
    exit /b 1
)

echo ✅ Бэкап создан успешно
echo.

REM Выполняем замену с помощью PowerShell для точности
echo 🔄 Выполняем замену в файле...

powershell -Command ^
"$content = Get-Content '%EXTRACTOR_FILE%' -Raw; ^
$oldPattern = 'WHERE creature\.id = '; ^
$newPattern = 'WHERE creature.%FIELD_NAME% = '; ^
$newContent = $content -replace [regex]::Escape($oldPattern), $newPattern; ^
Set-Content '%EXTRACTOR_FILE%' -Value $newContent -NoNewline"

if %ERRORLEVEL% neq 0 (
    echo ❌ Ошибка при замене!
    echo 🔄 Восстанавливаем из бэкапа...
    copy "%BACKUP_FILE%" "%EXTRACTOR_FILE%" > nul
    pause
    exit /b 1
)

echo ✅ Замена выполнена успешно!
echo.

REM Проверяем результат
echo 🔍 Проверяем изменения...
findstr /n "WHERE creature\.%FIELD_NAME% = " "%EXTRACTOR_FILE%" > nul

if %ERRORLEVEL% == 0 (
    echo ✅ УСПЕХ! Найдено: WHERE creature.%FIELD_NAME% =
    echo.
    echo 📊 Строки с изменениями:
    findstr /n "WHERE creature\.%FIELD_NAME% = " "%EXTRACTOR_FILE%"
    echo.
    echo 🎯 СЛЕДУЮЩИЕ ШАГИ:
    echo 1. Запусти: lua extractor.lua
    echo 2. Проверь output/units.lua на наличие координат
    echo 3. Если координаты есть - запусти transfer_files.bat
    echo 4. Перезапусти WoW и выполни /pftest

) else (
    echo ⚠️  Замена выполнена, но паттерн не найден
    echo 💡 Возможно поле уже было исправлено или файл имеет другую структуру
)

echo.
echo 📄 Файлы:
echo    Оригинал (бэкап): %BACKUP_FILE%
echo    Измененный файл:  %EXTRACTOR_FILE%
echo.
pause
