local ini_path = [[C:\Users\Tony Wonka\AppData\Roaming\REAPER\reaper-vstplugins64.ini]]
local target_dir = [[C:\Users\Tony Wonka\AppData\Roaming\REAPER\Scripts\Place2b\test\]]
local prefix = "p2b_InsertFX_"

reaper.RecursiveCreateDirectory(target_dir, 0)

-- Ваш список (без Melda)
local raw_user_list = {
  "AnalogObsession LA-2A", "AnalogObsession SPRECOMP", "AnalogObsession TuPre", "ArtsAcoustic Rever",
  "Bitspeek", "Boost", "CASSETE", "CLA vocal", "Convolver KHS", "CrowdChamber", "Crystallizer",
  "Dimension Exp", "Disperser", "Dual Delay", "DubStation 1.5", "Echobode", "Effectrix", "ENDLESS SMILE",
  "Fabfilter Pro C2", "FabFilter Pro MB", "FabFilter Pro-R", "FFT Pitch-Experimenter", "Flanger KHS",
  "HDelay", "KHS Transient Shaper", "Khz Distortion", "Khz Faturator", "Khz FreqShifter", "Khz Resonator",
  "MISHBY", "MSED", "nUGEN STEREOPLACER", "Ozon 9 Dynamics", "Ozon Imager", "Pitchmonster",
  "PitchShifter 2 JS", "PITCHSHIFTER KILOHEARTS", "PORTAL", "Pulsar 1176", "Pulsar 1178", "REAPitch",
  "Saike Pitch Shifter", "Sausage Fattner", "SDRR2", "Soundshifter Waves", "Soundtoys", "Texture",
  "Thermal", "Transient Master", "Transient Shaper", "True Dynamics", "UAD 1176", "UAD LA-2",
  "Vallhalla Delay", "Vallhalla Plate", "Vallhalla Room", "Vallhalla Shimmer", "Vallhalla Supermassive",
  "Vallhalla UBERMOD", "Vallhalla Ubermod", "Vallhalla VintageVerb", "Virtual Mix Rack", "Vocal Synth 2",
  "WARMVERB", "Waves - CLA 2A", "Waves - CLA 3A", "Waves - CLA 1176", "Waves - Rbass", "WIDER", "Xbass",
  "Multipass Kiloheartz", "NLS", "Saturn 2", "TIMELESS", "Warm", "Rave Generator 3", "Addictive Drums 2",
  "Addictive keys", "Albino", "Analogue Lab 4", "Current", "Diva", "Donk Machine", "EZ keys", "jD800",
  "Kick 2", "Kick Ninja", "Kontakt 7", "M1", "Massive", "Nexus 3", "Omnisphere", "PhasePlant",
  "PREDATOR", "Rave Generator", "Reaktor", "Repro", "Roland TB-303", "RS5K", "Sample Tank", "Scaler 3",
  "Serum 1", "Serum 2", "SPIRE", "SRX Orchestra", "Sylenth1", "Synplant", "VITAL"
}

-- Нормализация строк для сопоставления
local function normalize(str)
  if not str then return "" end
  str = str:lower()
  str = str:gsub("vst3?", "")
  str = str:gsub("automap", "")
  str = str:gsub("%f[%a%d][xX]?64%f[%A%d]", "")
  str = str:gsub("%f[%a%d][xX]?32%f[%A%d]", "")
  str = str:gsub("%(resources%)", "")
  str = str:gsub("[^%w]", "") -- Убираем знаки препинания и пробелы
  return str
end

-- 1. Считываем INI файл и индексируем плагины (Приоритет: VST3 -> VST/DLL)
local vst_db = {}

local file = io.open(ini_path, "r")
if file then
  for line in file:lines() do
    if line:find("=") then
      local file_part, data_part = line:match("^([^=]+)=(.*)")
      if file_part and data_part then
        -- Извлекаем точное имя плагина (после последней запятой)
        local real_name = data_part:match("[^,]+$")
        if real_name then
          -- Очищаем имя от системных суффиксов REAPER (!!!VSTi, !!!VST и т.д.)
          real_name = real_name:gsub("!!!.*$", ""):gsub("%s*%(.-%)%s*$", "")
          
          local is_vst3 = file_part:lower():find("%.vst3") ~= nil
          local norm_key = normalize(real_name)
          
          -- Записываем VST3 приоритетно перед DLL
          if norm_key ~= "" then
            if not vst_db[norm_key] or is_vst3 then
              vst_db[norm_key] = { name = real_name, is_vst3 = is_vst3 }
            end
          end
        end
      end
    end
  end
  file:close()
end

-- 2. Обработка списка и создание файлов
local count = 0
local created_names = {}

for _, user_item in ipairs(raw_user_list) do
  local norm_user = normalize(user_item)
  local final_name = nil

  -- Поиск совпадения в базе плагинов
  if vst_db[norm_user] then
    final_name = vst_db[norm_user].name
  else
    -- Если в ini точного совпадения нет (или это JSFX / специфическое имя) — очищаем пользовательское имя
    final_name = user_item:gsub("%s*%([Rr]esources%)", "")
                          :gsub("%f[%a%d][xX]?64%f[%A%d]", "")
                          :gsub("%f[%a%d][xX]?32%f[%A%d]", "")
                          :gsub("%s+", " "):match("^%s*(.-)%s*$")
  end

  if final_name and final_name ~= "" and not created_names[final_name] then
    -- Формируем имя файла с префиксом p2b_InsertFX_
    local file_path = target_dir .. prefix .. final_name .. ".txt"
    
    local f = io.open(file_path, "w")
    if f then
      f:close()
      created_names[final_name] = true
      count = count + 1
    end
  end
end

reaper.ShowConsoleMsg("Успешно создано файлов: " .. tostring(count) .. "\n")