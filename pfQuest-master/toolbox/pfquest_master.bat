@echo off
chcp 65001 > nul
title pfQuest Auto Debug Master
color 0A

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                🎯 pfQuest Auto Debug Master 🎯                ║
echo ║              Автоматизация отладки pfQuest                   ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

:MENU
echo 🎮 ГЛАВНОЕ МЕНЮ:
echo ================
echo.
echo [1] 🔍 SQL Диагностика (найти правильное поле)
echo [2] 🔧 Исправить extractor.lua автоматически
echo [3] 📊 Быстрый тест экстракции (1 существо)
echo [4] 🚀 Полная экстракция
echo [5] 📁 Копировать файлы в WoW
echo [6] 🎯 Показать статус файлов
echo [7] 🧹 Очистить временные файлы
echo [0] ❌ Выход
echo.
set /p choice="Выбери опцию (0-7): "

if "%choice%"=="1" goto SQL_DIAGNOSTIC
if "%choice%"=="2" goto FIX_EXTRACTOR
if "%choice%"=="3" goto QUICK_TEST
if "%choice%"=="4" goto FULL_EXTRACTION
if "%choice%"=="5" goto COPY_FILES
if "%choice%"=="6" goto SHOW_STATUS
if "%choice%"=="7" goto CLEANUP
if "%choice%"=="0" goto EXIT

echo ❌ Неверный выбор! Попробуй снова.
echo.
goto MENU

:SQL_DIAGNOSTIC
echo.
echo 🔍 Запускаем SQL диагностику...
echo ================================
call sql_diagnostic.bat
echo.
echo 💡 АНАЛИЗ РЕЗУЛЬТАТА:
if exist pfquest_diagnostic_report.txt (
    echo ✅ Отчет создан: pfquest_diagnostic_report.txt
    echo.
    echo 📊 Ищем правильное поле...
    findstr /C:"matches_by_entry" pfquest_diagnostic_report.txt > temp_result.txt
    set /p entry_result=<temp_result.txt
    findstr /C:"matches_by_id" pfquest_diagnostic_report.txt > temp_result2.txt
    set /p id_result=<temp_result2.txt

    echo ➤ По entry: !entry_result!
    echo ➤ По id: !id_result!

    del temp_result.txt temp_result2.txt 2>nul

    echo.
    echo 🎯 РЕКОМЕНДАЦИЯ:
    echo Если "matches_by_entry" показывает большое число - используй 'entry'
    echo Если "matches_by_id" показывает большое число - используй 'id'
)
echo.
pause
goto MENU

:FIX_EXTRACTOR
echo.
echo 🔧 Исправление extractor.lua
echo =============================
echo.
echo Доступные поля:
echo [1] entry   ^(самое частое для AzerothCore^)
echo [2] id      ^(оригинальное^)
echo [3] id1     ^(старые версии^)
echo [4] guid    ^(уникальный ID спавна^)
echo [5] Ввести свое
echo.
set /p fix_choice="Выбери поле (1-5): "

if "%fix_choice%"=="1" set FIELD=entry
if "%fix_choice%"=="2" set FIELD=id
if "%fix_choice%"=="3" set FIELD=id1
if "%fix_choice%"=="4" set FIELD=guid
if "%fix_choice%"=="5" (
    set /p FIELD="Введи название поля: "
)

if "%FIELD%"=="" (
    echo ❌ Поле не выбрано!
    goto MENU
)

echo.
echo 🎯 Исправляем на поле: %FIELD%
call fix_extractor.bat %FIELD%
echo.
pause
goto MENU

:QUICK_TEST
echo.
echo 📊 Быстрый тест экстракции (1 существо)
echo ========================================
echo.

REM Создаем временный конфиг для быстрого теста
echo 🔧 Настраиваем быстрый режим...

REM Бэкапим оригинальный extractor
if not exist extractor_original.lua (
    copy extractor.lua extractor_original.lua > nul
    echo ✅ Создан бэкап оригинального extractor.lua
)

REM Модифицируем для быстрого теста
powershell -Command ^
"(Get-Content extractor.lua) -replace 'LIMIT \d+', 'LIMIT 1' | Set-Content extractor_test.lua"

echo 🚀 Запускаем тестовую экстракцию...
lua extractor_test.lua

echo.
echo 🔍 Проверяем результат...
if exist output\units.lua (
    findstr /C:"coords = {" output\units.lua > nul
    if %ERRORLEVEL% == 0 (
        echo ✅ Координаты найдены в units.lua!
        echo 📊 Первые координаты:
        findstr /C:"coords = {" output\units.lua | head -3
        echo.
        echo 🎯 ТЕСТ УСПЕШЕН! Можно делать полную экстракцию.
    ) else (
        echo ❌ Координаты не найдены - поле неправильное
        echo 💡 Вернись к SQL диагностике или попробуй другое поле
    )
) else (
    echo ❌ Файл output\units.lua не создан - ошибка экстракции
)

del extractor_test.lua 2>nul
echo.
pause
goto MENU

:FULL_EXTRACTION
echo.
echo 🚀 Полная экстракция pfQuest
echo =============================
echo.

REM Восстанавливаем оригинальный файл если есть
if exist extractor_original.lua (
    copy extractor_original.lua extractor.lua > nul
    echo 🔄 Восстановлен оригинальный extractor.lua
)

echo ⚠️  Это может занять 10-30 минут в зависимости от размера БД
set /p confirm="Продолжить полную экстракцию? (y/n): "

if /i not "%confirm%"=="y" goto MENU

echo.
echo 🕐 Начинаем экстракцию... (время начала: %time%)
lua extractor.lua

echo.
echo ✅ Экстракция завершена! (время окончания: %time%)
echo.
echo 📊 Проверяем результаты...

if exist output\units.lua (
    for %%I in (output\units.lua) do echo ➤ units.lua: %%~zI байт
)
if exist output\quests.lua (
    for %%I in (output\quests.lua) do echo ➤ quests.lua: %%~zI байт
)
if exist output\objects.lua (
    for %%I in (output\objects.lua) do echo ➤ objects.lua: %%~zI байт
)

echo.
pause
goto MENU

:COPY_FILES
echo.
echo 📁 Копирование файлов в WoW
echo ============================
echo.

if exist transfer_files.bat (
    echo 🚀 Запускаем transfer_files.bat...
    call transfer_files.bat
) else (
    echo ❌ transfer_files.bat не найден!
    echo 💡 Убедись что находишься в папке pfQuest-master\toolbox\
)

echo.
pause
goto MENU

:SHOW_STATUS
echo.
echo 📊 Статус файлов pfQuest
echo =========================
echo.

echo 🔧 EXTRACTOR FILES:
if exist extractor.lua echo ✅ extractor.lua
if exist extractor_original.lua echo ✅ extractor_original.lua (бэкап)
if not exist extractor.lua echo ❌ extractor.lua отсутствует!

echo.
echo 📄 OUTPUT FILES:
for %%f in (output\*.lua) do (
    echo ✅ %%f - !
    for %%I in (%%f) do echo    Размер: %%~zI байт, Изменен: %%~tI
)

echo.
echo 📋 DIAGNOSTIC FILES:
if exist pfquest_diagnostic_report.txt (
    echo ✅ pfquest_diagnostic_report.txt
    for %%I in (pfquest_diagnostic_report.txt) do echo    Размер: %%~zI байт, Создан: %%~tI
)

echo.
echo 🎯 РЕКОМЕНДАЦИИ:
if not exist output\units.lua echo ❌ Нужна экстракция - units.lua отсутствует
if exist output\units.lua (
    findstr /C:"coords = {}" output\units.lua > nul
    if %ERRORLEVEL% == 0 echo ⚠️  units.lua содержит пустые координаты - проверь поле связи
)

echo.
pause
goto MENU

:CLEANUP
echo.
echo 🧹 Очистка временных файлов
echo ============================
echo.

echo Удаляем временные файлы...
del pfquest_diagnostic_report.txt 2>nul
del extractor_test.lua 2>nul
del temp_*.txt 2>nul

echo ✅ Очистка завершена
echo.
pause
goto MENU

:EXIT
echo.
echo 👋 Удачи с pfQuest!
echo.
exit

REM Включаем расширенные переменные для корректной работы
setlocal EnableDelayedExpansion
