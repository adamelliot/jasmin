require 'jsmin'

# This module is hooked into ActionContoller so it automatically jsmins your
# JavaScripts. The code here is heavily based off of SASS.
module Jasmin
  class << self
    @@options = {
      :template_location  => './public/javascripts/jasmin',
      :js_location        => './public/javascripts',
      :always_update      => false,
      :always_check       => true,
      :dont_minify        => false # Use this to check that your new JS works
    }
    @@checked_for_updates = false

    def checked_for_updates
      @@checked_for_updates
    end

    # Gets various options for Jazz. See README.rdoc for details.
    #--
    # TODO: *DOCUMENT OPTIONS*
    #++
    def options
      @@options
    end

    # Sets various options for Jasmin.
    def options=(value)
      @@options.merge!(value)
    end

    # Checks each javascript in <tt>options[:js_location]</tt>
    # to see if it needs updating,
    # and updates it using the corresponding javascript
    # from <tt>options[:template_location]</tt>z
    # if it does.
    def update_javascripts
      return if options[:never_update]

      @@checked_for_updates = true
      Dir.glob(File.join(options[:template_location], "**", "*.js")).entries.each do |file|

        # Get the relative path to the file with no extension
        name = file.sub(options[:template_location] + "/", "")[0...-3]

        if !forbid_update?(name) && (options[:always_update] || javascript_needs_update?(name))
          js = js_filename(name)
          File.delete(js) if File.exists?(js)

          filename = template_filename(name)
          result = begin
                     if (RAILS_ENV == "production" || options[:always_minify]) && (not options[:never_minify])
                       JSMin.minify(File.read(filename))
                     else  
                       File.read(filename)
                     end
                   rescue Exception => e
                     exception_string(e)
                   end

          # Create any directories that might be necessary
          dirs = [options[:js_location]]
          name.split("/")[0...-1].each { |dir| dirs << "#{dirs[-1]}/#{dir}" }
          dirs.each { |dir| Dir.mkdir(dir) unless File.exist?(dir) }

          # Finally, write the file
          File.open(js, 'w') do |file|
            file.print(result)
          end
        end
      end
    end

    private
  
    def exception_string(e)
      e_string = "#{e.class}: #{e.message}"
      <<END
/*
#{e_string}

Backtrace:\n#{e.backtrace.join("\n")}
*/
body:before {
white-space: pre;
font-family: monospace;
content: "#{e_string.gsub('"', '\"').gsub("\n", '\\A ')}"; }
END
    end

    def template_filename(name)
      "#{options[:template_location]}/#{name}.js"
    end

    def js_filename(name)
      "#{options[:js_location]}/#{name}.js"
    end

    def forbid_update?(name)
      name.sub(/^.*\//, '')[0] == ?_
    end

    def javascript_needs_update?(name)
      if !File.exists?(js_filename(name))
        return true
      else
        js_mtime = File.mtime(js_filename(name))
        File.mtime(template_filename(name)) > js_mtime
      end
    end

  end
end

# :stopdoc:
module ActionController
  class Base
    alias_method :jasmin_old_process, :process
    def process(*args)
      if !Jasmin.checked_for_updates ||
          Jasmin.options[:always_update] || Jasmin.options[:always_check]
        Jasmin.update_javascripts
      end
      
      jasmin_old_process(*args)
    end
  end
end