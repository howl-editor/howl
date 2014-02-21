-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, Project from howl
import Matcher from howl.util

separator = howl.fs.File.separator

display_name = (file, root) ->
  name = file\relative_to_parent root
  name ..= separator if file.is_directory
  name

separator_count = (s) ->
  start = 1
  count = 0
  while start
    start = s\find separator, start, true
    if start
      break if start == #s
      count += 1
      start += 1
  count

sort_paths = (paths) ->
  table.sort paths, (a, b) ->
    a_count = separator_count a
    b_count = separator_count b
    return a_count < b_count if a_count != b_count
    a < b

load_matcher = (project) ->
  root = project.root
  files = project\files!
  paths = [display_name f, root for f in *files]
  sort_paths paths
  Matcher paths, reverse: true

highlighter = (search, text) ->
  Matcher.explain search, text, reverse: true

class ProjectFileInput
  new: =>
    if app.editor
      file = app.editor.buffer.file
      if file
        @project = Project.for_file file

  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    return {} if not @project
    @matcher = load_matcher(@project) unless @matcher

    completion_options = {
      title: @project.root.path .. separator
      list:
        :highlighter
        column_styles: (name) ->
          name\match(separator .. '$') and 'keyword' or 'string'
      }

    matches = @matcher and self.matcher(text) or {}
    return matches, completion_options

  value_for: (path) => @project and (@project.root / path) or nil

howl.inputs.register 'project_file', ProjectFileInput
return ProjectFileInput
