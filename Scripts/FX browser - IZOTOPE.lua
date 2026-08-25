-- =====================================================================
-- Исправленный скрипт: Открытие FX Browser и безопасная фильтрация "RX"
-- =====================================================================

local track = reaper.GetSelectedTrack(0, 0)
if not track then
    reaper.MB("Пожалуйста, выделите хотя бы один трек!", "Ошибка", 0)
    return
end

if not reaper.APIExists("JS_Window_Find") then
    reaper.MB("Требуется библиотека JS_ReaScriptAPI (установите через ReaPack)", "Ошибка", 0)
    return
end

-- Нативный экшен открытия FX Browser для текущего трека
reaper.Main_OnCommand(40847, 0)
local TIME_START = reaper.time_precise()

local function FilterRX()
    -- Защита от бесконечного цикла (прерываем поиск через 3 секунды)
    if reaper.time_precise() - TIME_START > 3.0 then return end

    -- Ищем окно браузера эффектов по стандартным заголовкам
    local hwnd = reaper.JS_Window_Find("Add FX to", false)
    if not hwnd then hwnd = reaper.JS_Window_Find("FX Browser", false) end
    if not hwnd then hwnd = reaper.JS_Window_Find("FX: ", false) end

    -- Важно: проверяем, что окно найдено, видимо и точно НЕ является главным окном REAPER
    if hwnd and hwnd ~= reaper.GetMainHwnd() and reaper.JS_Window_IsVisible(hwnd) then
        local edit_hwnd = nil
        
        -- Получаем массив всех дочерних элементов этого окна
        local arr = reaper.new_array({}, 255)
        reaper.JS_Window_ArrayAllChild(hwnd, arr)
        local children = arr.table()

        -- Перебираем элементы в поисках поля ввода (строки поиска с классом Edit)
        for i = 1, #children do
            local child = reaper.JS_Window_HandleFromAddress(children[i])
            local class = reaper.JS_Window_GetClassName(child)
            
            if class == "Edit" or class == "EDIT" then
                edit_hwnd = child
                break
            end
        end

        if edit_hwnd then
            reaper.JS_Window_SetFocus(edit_hwnd)
            
            -- Безопасно вставляем нужный префикс
            reaper.JS_Window_SetTitle(edit_hwnd, "RX")
            
            -- Эмуляция нажатия "Пробел" (0x20) и "Backspace" (0x08)
            -- Это вызовет штатный триггер SWELL/Win32 и отфильтрует список без сбоев
            reaper.JS_WindowMessage_Send(edit_hwnd, "WM_KEYDOWN", 0x20, 0, 0, 0)
            reaper.JS_WindowMessage_Send(edit_hwnd, "WM_KEYUP", 0x20, 0, 0, 0)
            reaper.JS_WindowMessage_Send(edit_hwnd, "WM_KEYDOWN", 0x08, 0, 0, 0)
            reaper.JS_WindowMessage_Send(edit_hwnd, "WM_KEYUP", 0x08, 0, 0, 0)

            return -- Успех, останавливаем цикл отложенных вызовов
        end
    end

    -- Если окно или поле еще не отрисовались, повторяем проверку на следующем кадре интерфейса
    reaper.defer(FilterRX)
end

-- Запускаем асинхронный поиск окна
reaper.defer(FilterRX)
