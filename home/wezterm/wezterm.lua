local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- macOSのoptionキーをAlt(Meta)として扱う (ghostty: macos-option-as-alt = true)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- 背景の透過とブラー (ghostty: background-opacity / background-blur-radius)
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

-- 非アクティブなsplitを少し暗くする (ghostty: unfocused-split-opacity = 0.85)
-- weztermに透過指定はないため明度で近似する
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 0.85,
}

-- shell integration はweztermに組み込みのため設定不要 (ghostty: shell-integration = zsh)

config.keys = {
	-- cmd+rで設定を再読み込み (ghostty: super+r=reload_config)
	{ key = "r", mods = "CMD", action = act.ReloadConfiguration },

	-- ブラウザライクにcmd+opt+矢印でタブ移動
	{ key = "RightArrow", mods = "CMD|ALT", action = act.ActivateTabRelative(1) },
	{ key = "LeftArrow", mods = "CMD|ALT", action = act.ActivateTabRelative(-1) },

	-- splitのリサイズ (ghostty: super+shift+矢印=resize_split:...,10)
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 10 }) },
	{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 10 }) },
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 10 }) },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 10 }) },

	-- 画面とスクロールバックをクリア (ghostty: super+l=clear_screen)
	{ key = "l", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

	-- タブ名を変更 (cmd+eで入力プロンプトを表示)
	{
		key = "e",
		mods = "CMD",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

return config
