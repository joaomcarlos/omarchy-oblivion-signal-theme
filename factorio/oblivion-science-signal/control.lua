-- Oblivion Signal science telemetry.
--
-- Writes one JSON line per second to script-output/oblivion-science.jsonl for
-- the Oblivion Signal desktop rail to graph: the current research, its
-- progress, and science packs consumed per minute.
--
-- Science per minute comes from the item production statistics, where the
-- "output" side is consumption (the GUI shows consumption on the right).

local OUTPUT_FILE = "oblivion-science.jsonl"
local SAMPLE_INTERVAL = 60 -- ticks: one sample per second
local ROTATE_AFTER = 3600 -- samples: rewrite the file rather than grow forever

-- Union of every technology's research ingredients: authoritative across
-- vanilla, Space Age, and modded science packs. Built once, cached in storage.
local function collect_science_packs()
  local packs, seen = {}, {}
  for _, tech in pairs(prototypes.technology) do
    for _, ingredient in pairs(tech.research_unit_ingredients or {}) do
      -- The runtime returns {name = ..., amount = ...} (the prototype docs
      -- show the data-stage tuple form, which reads as [1]).
      local name = ingredient.name or ingredient[1]
      if name and not seen[name] then
        seen[name] = true
        packs[#packs + 1] = name
      end
    end
  end
  table.sort(packs)
  return packs
end

local function round1(value)
  return math.floor(value * 10 + 0.5) / 10
end

local function sample()
  if not storage.science_packs then
    storage.science_packs = collect_science_packs()
  end

  local force = game.forces.player
  local stats = {}
  for _, surface in pairs(game.surfaces) do
    stats[#stats + 1] = force.get_item_production_statistics(surface)
  end

  local spm, total = {}, 0
  for _, name in ipairs(storage.science_packs) do
    local rate = 0
    for _, flow in ipairs(stats) do
      rate = rate + flow.get_flow_count({
        name = name,
        category = "output",
        precision_index = defines.flow_precision_index.one_minute,
      })
    end
    rate = round1(rate)
    spm[name] = rate
    total = total + rate
  end

  local tech = force.current_research
  local line = helpers.table_to_json({
    t = game.tick,
    tech = tech and tech.name or "",
    prog = tech and round1(force.research_progress * 100) or 0,
    queue = force.research_queue[1] or "",
    spm = spm,
    total = round1(total),
  })

  local append = not storage.start_fresh
  storage.start_fresh = false
  storage.samples = storage.samples + 1
  if storage.samples > ROTATE_AFTER then
    storage.samples = 1
    append = false
  end

  helpers.write_file(OUTPUT_FILE, line .. "\n", append)
end

script.on_init(function()
  storage.science_packs = collect_science_packs()
  storage.samples = 0
  storage.start_fresh = true
end)

script.on_configuration_changed(function()
  storage.science_packs = collect_science_packs()
end)

script.on_nth_tick(SAMPLE_INTERVAL, sample)
