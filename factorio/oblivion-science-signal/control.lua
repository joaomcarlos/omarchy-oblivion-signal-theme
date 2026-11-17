-- Oblivion Signal science telemetry.
--
-- Sends one JSON sample per second as a UDP datagram to the Oblivion Signal
-- desktop rail (127.0.0.1:34200), which graphs the current research, its
-- progress, and science packs consumed per minute. The rail ACKs each
-- datagram back to the game's --enable-lua-udp port; while those ACKs keep
-- arriving the mod does no file IO at all. Without the flag send_udp/recv_udp
-- are silent no-ops, no ACK ever comes back, and the file fallback engages:
-- one JSON line per second appended to script-output/oblivion-science.jsonl.
--
-- Science per minute comes from the item production statistics, where the
-- "output" side is consumption (the GUI shows consumption on the right).
-- Reading those statistics is the expensive part — one LuaFlowStatistics
-- object plus ~12 flow_count reads per surface — so instead of paying it
-- all in one tick, a sweep job walks a few surfaces per tick and the emit
-- tick only encodes the accumulated totals.

local OUTPUT_FILE = "oblivion-science.jsonl"
local TELEMETRY_PORT = 34200 -- the rail's listener port; ACKs come from here
local SAMPLE_INTERVAL = 60 -- ticks: one sample per second
local ROTATE_AFTER = 3600 -- samples: rewrite the file rather than grow forever
local ACK_FRESH_TICKS = 120 -- no ACK within this window -> file writes resume

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

-- Sweep state lives in upvalues, not storage: it is transient by design and
-- simply restarts on load. `sweep` is the in-flight job; `accumulated`
-- holds the {pack -> summed rate} map from the last completed pass.
local sweep
local accumulated

local function start_sweep()
  local surfaces = {}
  for _, surface in pairs(game.surfaces) do
    surfaces[#surfaces + 1] = surface
  end
  sweep = {
    surfaces = surfaces,
    -- Pace the pass to finish inside the window; +1 absorbs surfaces added
    -- while the sweep is in flight.
    budget = math.ceil(#surfaces / (SAMPLE_INTERVAL - 1)) + 1,
    index = 1,
    totals = {},
  }
end

local function step_sweep()
  local force = game.forces.player
  local last = math.min(sweep.index + sweep.budget - 1, #sweep.surfaces)
  for i = sweep.index, last do
    local surface = sweep.surfaces[i]
    if surface.valid then
      local flow = force.get_item_production_statistics(surface)
      for _, name in ipairs(storage.science_packs) do
        sweep.totals[name] = (sweep.totals[name] or 0) + flow.get_flow_count({
          name = name,
          category = "output",
          precision_index = defines.flow_precision_index.one_minute,
        })
      end
    end
  end
  sweep.index = last + 1
  if sweep.index > #sweep.surfaces then
    accumulated = sweep.totals
    -- Persist the finished pass so the first emit after a load reuses real
    -- numbers instead of dipping to zero until a fresh sweep completes.
    storage.last_totals = accumulated
    sweep = nil -- idle until the next emit starts a fresh pass
  end
end

local function emit()
  local force = game.forces.player
  local totals = accumulated or storage.last_totals or {}

  local spm, total = {}, 0
  for _, name in ipairs(storage.science_packs) do
    local rate = round1(totals[name] or 0)
    spm[name] = rate
    total = total + rate
  end

  local tech = force.current_research
  -- Effective research rate: units of the current technology completed per
  -- minute, measured from progress deltas over a ~60s window. Productivity,
  -- lab speed and drain bonuses all show up in the progress rate, so this is
  -- the real "SPM being researched" — raw pack consumption (spm above) is
  -- what the factory physically pulls. The window smooths the bursts a
  -- cargo-delivered factory produces; a tech switch or level wrap resets the
  -- contiguous run so completion jumps never read as backward deltas.
  local research_rate = 0
  if tech then
    local ring = storage.progress_samples or {}
    storage.progress_samples = ring
    ring[#ring + 1] = {
      tick = game.tick,
      progress = force.research_progress or 0,
      name = tech.name,
    }
    if #ring > 64 then table.remove(ring, 1) end
    local newest = ring[#ring]
    local oldest = newest
    for i = #ring - 1, 1, -1 do
      local s = ring[i]
      if s.name ~= tech.name or s.progress > oldest.progress then break end
      oldest = s
    end
    local dt = newest.tick - oldest.tick
    if dt > 0 then
      research_rate = (newest.progress - oldest.progress)
        * (tech.research_unit_count or 1) * 3600 / dt
    end
    -- Research-queue jugglers can swap current_research every few seconds;
    -- each switch resets the progress window, which reads as a spike to zero
    -- on the rail's trace. Carry the last trustworthy rate until ~10s of
    -- contiguous same-tech data has accumulated, then let the real value
    -- take over again (a genuinely stalled tech still decays to zero).
    if dt >= 600 then
      storage.last_rate = research_rate
    elseif storage.last_rate then
      research_rate = storage.last_rate
    end
  else
    storage.progress_samples = {}
    storage.last_rate = nil
  end

  local line = helpers.table_to_json({
    t = game.tick,
    tech = tech and tech.name or "",
    prog = tech and round1(force.research_progress * 100) or 0,
    rate = round1(research_rate),
    queue = force.research_queue[1] or "",
    spm = spm,
    total = round1(total),
  })

  helpers.send_udp(TELEMETRY_PORT, line)
  -- Pump the inbound socket so on_udp_packet_received can dispatch; no-op
  -- when the game wasn't launched with --enable-lua-udp.
  helpers.recv_udp()

  local udp_live = storage.udp_last_ack ~= nil
      and (game.tick - storage.udp_last_ack) < ACK_FRESH_TICKS
  -- The tick guard keeps a second emission of the same tick from appending
  -- twice. Reloads that replay the same boundary still append one line per
  -- session — truthful, and undetectable from inside the mod.
  if not udp_live and storage.last_written_tick ~= game.tick then
    storage.last_written_tick = game.tick
    local append = not storage.start_fresh
    storage.start_fresh = false
    storage.samples = (storage.samples or 0) + 1
    if storage.samples > ROTATE_AFTER then
      storage.samples = 1
      append = false
    end
    helpers.write_file(OUTPUT_FILE, line .. "\n", append)
  end
end

local function tick()
  if not storage.science_packs then
    storage.science_packs = collect_science_packs()
  end
  if game.tick % SAMPLE_INTERVAL == 0 then
    emit()
    start_sweep()
  elseif sweep then
    step_sweep()
  elseif not accumulated then
    -- Post-load the upvalues reset; start refreshing stale totals now
    -- rather than waiting for the next emit boundary.
    start_sweep()
  end
end

script.on_event(defines.events.on_udp_packet_received, function(event)
  -- The rail's listener ACKs from its bound port; one ACK is proof the flag
  -- is set, a listener is alive, and samples are being delivered.
  if event.source_port == TELEMETRY_PORT then
    storage.udp_last_ack = event.tick
  end
end)

script.on_init(function()
  storage.science_packs = collect_science_packs()
  storage.samples = 0
  storage.start_fresh = true
end)

script.on_configuration_changed(function()
  storage.science_packs = collect_science_packs()
end)

script.on_nth_tick(1, tick)
