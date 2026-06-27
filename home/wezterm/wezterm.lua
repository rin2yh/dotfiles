local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- フォント (ghostty: JetBrainsMono Nerd Font 13pt)
-- フォント未インストールを避けるため、wezterm内蔵の "JetBrains Mono" を使う。
-- 字形はghosttyと同じで、Nerd Fontアイコンもwezterm内蔵のシンボルで補完される。
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13.0

-- macOSのoptionキーをAlt(Meta)として扱う (ghostty: macos-option-as-alt = true)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- 背景の透過とブラー (ghostty: background-opacity / background-blur-radius)
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

-- weztermのデフォルト背景は真っ黒(#000000)でghosttyより暗く沈むため、
-- ghosttyのデフォルト背景色(#292c33)に合わせる
config.colors = {
	background = "#292c33",
}

-- WebGpuだとDock(launchd)起動時にGPUコンテキスト初期化に失敗して
-- 透過が効かないことがあるため、描画をOpenGLに固定する
config.front_end = "OpenGL"

-- 非アクティブなsplitを少し暗くする (ghostty: unfocused-split-opacity = 0.85)
-- weztermに透過指定はないため明度で近似する
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 0.85,
}

-- shell integration はweztermに組み込みのため設定不要 (ghostty: shell-integration = zsh)

-- タブバーをghostty風に寄せる
-- ・ファンシータブ(角丸)はデフォルトのまま
-- ・タブが1つのときはタブバーごと隠す (ghosttyと同じ挙動)
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- "1:" のインデックスを消して、タブ名(無ければプログラム名)だけ表示する
wezterm.on("format-tab-title", function(tab)
	local title = tab.tab_title
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	return " " .. title .. " "
end)

config.keys = {
	-- cmd+rで設定を再読み込み (ghostty: super+r=reload_config)
	{ key = "r", mods = "CMD", action = act.ReloadConfiguration },

	-- cmd+opt+矢印でタブ移動 / cmd+shift+矢印でsplitリサイズ は
	-- weztermのデフォルトと同一のため定義不要:
	--   ALT|SUPER 矢印  -> ActivateTabRelative
	--   SHIFT|SUPER 矢印 -> AdjustPaneSize(..., 10)

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
