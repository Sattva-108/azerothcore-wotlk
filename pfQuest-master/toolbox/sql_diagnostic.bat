@echo off
chcp 65001 > nul
echo 🔍 pfQuest SQL Diagnostic Tool
echo ================================

REM Настройки подключения к MySQL
set MYSQL_HOST=localhost
set MYSQL_PORT=3306
set MYSQL_USER=root
set MYSQL_PASSWORD=
set MYSQL_DATABASE=acore_world

REM Проверь настройки выше и измени если нужно!
echo 📊 Подключение к базе: %MYSQL_DATABASE% на %MYSQL_HOST%:%MYSQL_PORT%
echo.

REM Создаем временный SQL файл
set TEMP_SQL=%TEMP%\pfquest_diagnostic.sql

REM === ГЛАВНЫЙ ДИАГНОСТИЧЕСКИЙ SQL ===
(
echo -- pfQuest Diagnostic Report
echo -- ========================
echo.
echo SELECT 'TABLE STRUCTURES' as section;
echo.
echo SELECT 'creature table structure:' as info;
echo DESCRIBE creature;
echo.
echo SELECT 'creature_template table structure:' as info;
echo DESCRIBE creature_template;
echo.
echo SELECT 'SAMPLE DATA' as section;
echo.
echo SELECT 'First 3 creatures:' as info;
echo SELECT * FROM creature LIMIT 3;
echo.
echo SELECT 'First 3 creature_templates:' as info;
echo SELECT * FROM creature_template LIMIT 3;
echo.
echo SELECT 'FIELD CONNECTION TESTS' as section;
echo.
echo SELECT 'Testing creature.id = creature_template.entry:' as test;
echo SELECT COUNT(*^ as matches_by_id FROM creature c JOIN creature_template ct ON c.id = ct.entry LIMIT 1;
echo.
echo SELECT 'Testing creature.entry = creature_template.entry:' as test;
echo SELECT COUNT(*^ as matches_by_entry FROM creature c JOIN creature_template ct ON c.entry = ct.entry LIMIT 1;
echo.
echo SELECT 'Testing if id1 field exists:' as test;
echo SELECT COUNT(*^ as total_creatures FROM creature;
echo.
echo SELECT 'SPECIFIC CREATURE TEST (ID 1^:' as test;
echo SELECT 'creature_template entry=1:' as info;
echo SELECT entry, name FROM creature_template WHERE entry = 1;
echo.
echo SELECT 'creature spawns with id=1:' as info;
echo SELECT COUNT(*^ as spawns_by_id FROM creature WHERE id = 1;
echo.
echo SELECT 'creature spawns with entry=1:' as info;
echo SELECT COUNT(*^ as spawns_by_entry FROM creature WHERE entry = 1;
echo.
echo SELECT 'WORKING CONNECTION TEST' as section;
echo.
echo SELECT 'If entry field works - sample join:' as test;
echo SELECT c.guid, c.entry, c.position_x, c.position_y, c.map, ct.name
echo FROM creature c
echo JOIN creature_template ct ON c.entry = ct.entry
echo WHERE ct.entry = 1
echo LIMIT 3;
echo.
echo SELECT 'STATISTICS' as section;
echo.
echo SELECT 'Total creatures:' as info, COUNT(*^ as count FROM creature;
echo SELECT 'Total creature templates:' as info, COUNT(*^ as count FROM creature_template;
echo SELECT 'Unique creature entries:' as info, COUNT(DISTINCT entry^ as count FROM creature;
echo SELECT 'Creatures with coordinates:' as info, COUNT(*^ as count FROM creature WHERE position_x IS NOT NULL AND position_y IS NOT NULL;
) > "%TEMP_SQL%"

echo 💾 SQL файл создан: %TEMP_SQL%
echo.

REM Выполняем SQL запрос
echo 🚀 Выполняем диагностику...
echo.

mysql -h%MYSQL_HOST% -P%MYSQL_PORT% -u%MYSQL_USER% -p%MYSQL_PASSWORD% %MYSQL_DATABASE% < "%TEMP_SQL%" > pfquest_diagnostic_report.txt 2>&1

if %ERRORLEVEL% == 0 (
    echo ✅ Диагностика завершена успешно!
    echo 📄 Результат сохранен в: pfquest_diagnostic_report.txt
    echo.
    echo 🔍 КРАТКИЙ АНАЛИЗ:
    echo ==================

    REM Поиск ключевых результатов
    findstr /C:"matches_by_id" pfquest_diagnostic_report.txt > nul
    if %ERRORLEVEL% == 0 (
        echo ➤ Тест связи по creature.id:
        findstr /C:"matches_by_id" pfquest_diagnostic_report.txt
    )

    findstr /C:"matches_by_entry" pfquest_diagnostic_report.txt > nul
    if %ERRORLEVEL% == 0 (
        echo ➤ Тест связи по creature.entry:
        findstr /C:"matches_by_entry" pfquest_diagnostic_report.txt
    )

    findstr /C:"spawns_by_entry" pfquest_diagnostic_report.txt > nul
    if %ERRORLEVEL% == 0 (
        echo ➤ Спавны существа ID 1 по entry:
        findstr /C:"spawns_by_entry" pfquest_diagnostic_report.txt
    )

    echo.
    echo 📖 Полный отчет: pfquest_diagnostic_report.txt
    echo 🎯 Найди строку с максимальным количеством matches - это правильное поле!

) else (
    echo ❌ Ошибка подключения к базе данных!
    echo 🔧 Проверь настройки в начале файла:
    echo    MYSQL_HOST=%MYSQL_HOST%
    echo    MYSQL_PORT=%MYSQL_PORT%
    echo    MYSQL_USER=%MYSQL_USER%
    echo    MYSQL_DATABASE=%MYSQL_DATABASE%
    echo.
    echo 💡 Возможно нужно ввести пароль вручную
    type pfquest_diagnostic_report.txt
)

REM Удаляем временный файл
del "%TEMP_SQL%" 2>nul

echo.
echo 🎯 СЛЕДУЮЩИЙ ШАГ:
echo Если diagnostic показал что правильное поле = 'entry',
echo запусти: fix_extractor.bat entry
echo.
pause
