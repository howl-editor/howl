-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- A busted output handler for non-interactive runs.
--
-- The default handler (busted.output.utf_terminal) draws a progress circle per test,
-- which is useful when watching a run in a terminal but is pure noise once the output
-- is captured - a full suite emits thousands of control sequences around the few lines
-- that actually matter. This handler prints nothing while running and ends with a
-- single summary line, preceded by the details of any failure.
--
-- Selected automatically by bin/howl-spec when stdout is not a tty; force it with
-- 'bin/howl-spec --concise', or directly:
--
--   ./src/howl --spec --defer-print --output=spec/support/concise_output.lua <path>
--
-- It must be a .lua file: busted only treats --output as a path when it ends in .lua
-- (lib/ext/spec-support/busted/core.lua:89), otherwise it require's it as a module.

local function indent(text)
  return '  ' .. tostring(text):gsub('\n', '\n  ')
end

local function location(status)
  return status.info.short_src .. ' @ ' .. status.info.linedefined
end

local function collect(statuses, options, acc)
  for _, status in ipairs(statuses) do
    if status.type == 'description' then
      collect(status, options, acc)
    elseif status.type == 'success' then
      acc.successes = acc.successes + 1
    elseif status.type == 'failure' then
      acc.failures = acc.failures + 1
      local detail = 'FAIL ' .. location(status) ..
                     '\n' .. indent(status.description) ..
                     '\n' .. indent(status.err)
      if options.verbose and status.trace then
        detail = detail .. '\n' .. indent(status.trace)
      end
      acc.details[#acc.details + 1] = detail
    elseif status.type == 'pending' then
      acc.pendings = acc.pendings + 1
      if not options.suppress_pending then
        acc.details[#acc.details + 1] = 'PENDING ' .. location(status) ..
                                        '\n' .. indent(status.description)
      end
    end
  end

  return acc
end

-- NOTE: returned already constructed, not as a factory. busted calls the factory only
-- on the require path; for a --output=<path>.lua it uses whatever the chunk returns
-- (lib/ext/spec-support/busted/core.lua:89-96).
return {
  options = {},

  header = function() return '' end,

  -- Deliberately a no-op: this is the per-test progress indicator.
  currently_executing = function() end,

  formatted_status = function(statuses, options, ms)
    local acc = collect(statuses, options,
      { successes = 0, failures = 0, pendings = 0, details = {} })

    local summary = ('%d passed, %d failed, %d pending in %.3fs'):format(
      acc.successes, acc.failures, acc.pendings, ms)

    if #acc.details == 0 then
      return summary
    end

    return table.concat(acc.details, '\n\n') .. '\n\n' .. summary
  end
}
