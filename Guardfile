# Requires guard-shell (gem install guard-shell)

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
    "#{spec}: Specs run (#{Time.now.asctime})."
  end
end

guard :shell do

  directories %w(lib spec)

  watch %r|.*_spec\.moon$| do |m|
    process_spec m[0]
  end

  watch %r"lib/howl/.*\.(?:moon|lua)$" do |m|
    spec = m[0].gsub('lib/howl', 'spec').gsub(/\.(?:moon|lua)$/, '_spec.moon')
    process_spec spec
  end

  watch %r|lib/([^/]+).*\.moon$| do |m|
    spec = m[0].gsub(m[1], "#{m[1]}/spec").gsub('.moon', '_spec.moon')
    process_spec spec
  end

  watch %r|(bundles/[^/]+)/(.*)\.moon$| do |m|
    spec = "#{m[1]}/spec/#{m[2]}_spec.moon"
    process_spec spec
  end

 end
