-- Prometheus obfuscation config for ST Mine.
-- Safe set for a MoonLoader/LuaJIT script: string encryption + constant
-- array + mangled local names. No Vmify / AntiTamper (would break ffi
-- callbacks, coroutines and per-frame performance) and no
-- NumbersToExpressions (would risk altering route float coordinates).
return {
    LuaVersion    = "Lua51",
    VarNamePrefix = "",
    NameGenerator = "MangledShuffled",
    PrettyPrint   = false,
    Seed          = 0,
    Steps = {
        { Name = "EncryptStrings", Settings = {} },
        {
            Name = "ConstantArray",
            Settings = {
                Threshold             = 1,
                StringsOnly           = true,
                Shuffle               = true,
                Rotate                = true,
                LocalWrapperThreshold = 0,
            },
        },
    },
}
