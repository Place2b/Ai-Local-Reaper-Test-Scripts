local os_name = reaper.GetOS()

if os_name:find("Win") then
    -- Запуск для Windows
    os.execute('start splice:')
elseif os_name:find("OSX") or os_name:find("macOS") then
    -- Запуск для macOS
    os.execute('open -a "Splice"')
end
