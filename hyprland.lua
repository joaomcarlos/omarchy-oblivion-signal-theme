-- Oblivion Signal — Hyprland border and animation treatment
-- One-pixel cyan active border, muted structural-teal inactive border.
-- No shadows — flat screen/glass depth per the component language.
-- Animations: mechanical, goal-driven, fast — not smooth or decorative.
-- The ilikeinterfaces article describes the motion as "mechanical and
-- goal-driven" with "paranoia and incompleteness." TET doesn't care for
-- flashy animations. Transitions are fast, linear, and slightly abrupt.

local active_border_color = "rgb(6FA8CC)"
local inactive_border_color = "rgba(2C4A6199)"

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 1,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },

    layout = "dwindle",
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    rounding = 0,
    shadow = {
      enabled = false,
    },
    blur = {
      enabled = false,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Mechanical curves: as close to "stepped" as Hyprland beziers allow.
-- Hyprland doesn't support CSS steps() — only bezier curves.
-- These curves have near-vertical midpoints, creating a hard snap rather
-- than smooth easing. The effect is "mechanical, goal-driven" per the
-- ilikeinterfaces article: fast, slightly abrupt, not decorative.
hl.curve("mechanical", { type = "bezier", points = { { 0.05, 0 }, { 0.05, 1 } } })
hl.curve("snap", { type = "bezier", points = { { 0, 0.8 }, { 0.1, 1 } } })

-- Fast, mechanical animations — no popin, no smooth ease
-- Speeds are 2-3x the Omarchy defaults to match "impatience" from the article.
-- Windows slide (not popin) — the article says motion is "mechanical and
-- goal-driven," not bouncy or playful.
hl.animation({ leaf = "global", enabled = true, speed = 20, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 12, bezier = "snap" })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "mechanical" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 7, bezier = "mechanical", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "linear", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 7, bezier = "mechanical" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 7, bezier = "mechanical", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 4, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "mechanical", style = "slidevert" })

-- Oblivion Signal cursor theme (XCursor; Hyprland falls back from hyprcursor)
hl.env("XCURSOR_THEME", "oblivion-signal-cursors")
hl.env("XCURSOR_SIZE", "24")
