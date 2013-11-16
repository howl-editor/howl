# Requires guard-shell

def run_spec(spec)
  system("./bin/howl-spec #{spec}")
end

guard :shell do
  watch %r|spec/.*\.moon$| do |m|
    if run_spec(m[0])
      n "#{m[0]}: Specs passed", 'Busted', :success
    else
      n "#{m[0]}: Specs failed", 'Busted', :failed
    end
    m[0] + ": Specs run."
  end

  watch %r|lib/howl/.*\.moon$| do |m|
    spec = m[0].gsub('lib/howl', 'spec').gsub('.moon', '_spec.moon')
    if File.exists?(spec)
      if run_spec(spec)
        n "#{spec}: Specs passed", 'Busted', :success
      else
        n "#{spec}: Specs failed", 'Busted', :failed
      end
      m[0] + ": Specs run."
    end
  end
end
