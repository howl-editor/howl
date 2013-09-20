-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import Matcher from howl.util

class YesOrNoInput
  should_complete: -> true
  close_on_cancel: -> true

  new: (@default) =>
    @matcher = Matcher { 'Yes', 'No' }

  complete: (text) =>
    options = if text\match('^%s*$') then list: selection: @default and 'Yes' or 'No' else {}
    return self.matcher(text), options

  value_for: (answer) => if answer == 'Yes' then true else false

howl.inputs.register 'yes_or_no', YesOrNoInput
