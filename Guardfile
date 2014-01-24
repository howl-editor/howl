# Requires guard-shell

def run_spec(spec)
  system("./bin/howl-spec #{spec}")
end

def process_spec(spec)
  if File.exists?(spec)
    if run_spec(spec)
      n "#{spec}: Specs passed", 'Busted', :success
    else
      n "#{spec}: Specs failed", 'Busted', :failed
    end
    "#{spec}: Specs run."
  end
end

guard :shell do

  watch %r|spec/.*\.moon$| do |m|
    process_spec m[0]
  end

  watch %r|lib/howl/.*\.moon$| do |m|
    spec = m[0].gsub('lib/howl', 'spec').gsub('.moon', '_spec.moon')
    process_spec spec
  end

  watch %r|lib/([^/]+).*\.moon$| do |m|
    spec = m[0].gsub(m[1], "#{m[1]}/spec").gsub('.moon', '_spec.moon')
    process_spec spec
  end

 end
