# Update your github gem dependencies for gemcutter.
# Checks if the library exists on gemcutter yet before changing anything
#
# Usage:   ruby gemcutter_update.rb [DIRECTORY] [ENVIRONMENT]
# Example: gemcutter_update my_app test
# Default: gemcutter_update . production

require 'net/http'
require 'uri'

path        = ARGV[0] || '.'
environment =  ARGV[1] || 'production'

source         = "http://gems.github.com"
@gemcutter_url = "http://gemcutter.org"


def available_on_gemcutter?(library)
  url = URI.parse("#{@gemcutter_url}/gems/#{library}.json")
  puts "Checking if \"#{library}\" is available on Gemcutter..."
  response = Net::HTTP.start(url.host, url.port) do |http|
    http.get(url.path)
  end
  not response.body =~ /This rubygem could not be found/
end

def confirm?(file)
  return true if @confirmation == 'a'
  
  puts "Overwrite file \"#{file}\" with updated dependencies?"
  1.times do 
    print "[y]es, [n]o or [a]ll: "
    @confirmation = STDIN.gets.chomp
    redo unless @confirmation =~ /^[yna]$/
  end
  @confirmation =~ /y|a/
end


# main program start
@confirmation = nil
files = Dir["#{path}/**/config/environment.rb"]
files += Dir["#{path}/**/config/environments/#{environment}.rb"]

files.each do |file|
  updated_a_line = false
  puts "Scanning file #{file}"
  lines = File.readlines(file)
  lines.map! do |line|
    if line =~ /\s#/  # ignore comments
      line
    elsif line =~ /(\s*)config\.gem *['"]([^'"]+)['"] *, *(.+, *)?:source *=> *['"]#{source}['"](.*)$/
      # TODO: tokenizing the options (e.g. with String#split) is probably easier than using a regexp
      intendation, user_and_library, pre_options, post_options = $1, $2, $3, $4
      library = user_and_library.split('-').last

      # check if library is available on gemcutter
      if available_on_gemcutter?(library)
        new_line = "#{intendation}config.gem \"#{library}\", #{pre_options}:source => \"#{@gemcutter_url}\"#{post_options}\n"      
        puts "* Original line: #{line}"
        puts "* Updated line:  #{new_line}"
        updated_a_line = true

        new_line        
      else
        puts "WARNING: The gem \"#{library}\" is not yet available on Gemcutter, so updating this configuration line has been skipped."
        line
      end
    else
      line
    end
  end

  if updated_a_line and confirm?(file)
    File.open(file, 'w') do |f|
      f.write(lines)
    end
    puts "Updated file \"#{file}\""
  end
end