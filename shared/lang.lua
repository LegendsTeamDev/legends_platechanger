local Locales = {}
local currentLocale = Config.Lang

function LoadLocales(locale)
    local content = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(locale))
    if content then
        Locales[locale] = json.decode(content)
    else
        print(("Could not load locale file for '%s'"):format(locale))
        Locales[locale] = {}
    end
end

LoadLocales(currentLocale)

function _L(key, ...)
    local msg = Locales[currentLocale][key] or key
    if ... then
        return string.format(msg, ...)
    else
        return msg
    end
end
