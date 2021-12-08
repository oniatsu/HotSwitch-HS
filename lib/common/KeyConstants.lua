local key = {
    yen = 95,
    semicolon = 41,
    colon = 39,
    atmark = 33,
    openbracket = 30,
    closebracket = 42,
    hyphen = 27,
    hat = 24,
    comma = 93,
    dot = 47,
    slash = 44,
    underscore = 94,
}

local KeyConstants = {

    -- Sometimes, some special keys don't work
    BASIC_KEYS = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m",
                "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
                "-", "[", "]", ".", "/"},

    SHIFTABLE_KEYS = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"},

    DEFAULT_AUTO_GENERATED_KEYS = {"s", "a", "d", "f", "j", "k", "l", "e", "w", "c", "m", "p", "g", "h", "i", "o", "r", "t", "u", "n", "v", "b", "q", "x", "y", "z",
                                   "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
                                   "S", "A", "D", "F", "J", "K", "L", "E", "W", "C", "M", "P", "G", "H", "I", "O", "R", "T", "U", "N", "V", "B", "Q", "X", "Y", "Z"},

    ADDITIONAL_LAYOUT = {

        JAPANESE = {
            { {"shift"}, "1", "!" },
            { {"shift"}, "2", "\"" },
            { {"shift"}, "3", "#" },
            { {"shift"}, "4", "$" },
            { {"shift"}, "5", "%" },
            { {"shift"}, "6", "&" },
            { {"shift"}, "7", "'" },
            { {"shift"}, "8", "(" },
            { {"shift"}, "9", ")" },
            -- { {"shift"}, "0", "" }, -- not exist

            { {}, key.hat, "^" },
            -- { {}, "\\", "\\" }, -- invalid
            -- { {}, "¥", "¥" }, -- invalid
            { {"shift"}, key.hyphen, "=" },
            { {"shift"}, key.hat, "~" },
            -- { {"shift"}, "\\", "|" }, -- invalid
            -- { {"shift"}, "¥", "|" }, -- invalid
            -- { {"shift"}, key.yen, "|" }, -- invalid

            { {}, key.atmark, "@" },
            { {"shift"}, key.atmark, "`" },

            { {}, key.semicolon, ";" },
            { {}, key.colon, ":" },

            -- { {}, key.openbracket, "[" },
            -- { {}, key.closebracket, "]" },

            { {"shift"}, key.semicolon, "+" },
            { {"shift"}, key.colon, "*" },
            { {"shift"}, key.openbracket, "{" },
            { {"shift"}, key.closebracket, "}" },
            -- { {}, key.comma, "," }, -- invalid
            -- { {"shift"}, key.comma, "<" }, --invalid
            { {"shift"}, key.dot, ">" },
            { {"shift"}, key.slash, "?" },

            { {}, key.underscore, "_" },
            -- { {"shift"}, key.underscore, "" }, -- not exist
        },

    },

}
return KeyConstants