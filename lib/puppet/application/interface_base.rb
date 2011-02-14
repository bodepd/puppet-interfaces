require 'puppet/application'
require 'puppet/interface'

class Puppet::Application::InterfaceBase < Puppet::Application
  should_parse_config
  run_mode :agent

  def preinit
    super
    trap(:INT) do
      $stderr.puts "Cancelling Interface"
      exit(0)
    end
  end

  option("--debug", "-d") do |arg|
    Puppet::Util::Log.level = :debug
  end

  option("--verbose", "-v") do
    Puppet::Util::Log.level = :info
  end

  option("--format FORMAT") do |arg|
    @format = arg.to_sym
  end

  option("--mode RUNMODE", "-r") do |arg|
    raise "Invalid run mode #{arg}; supported modes are user, agent, master" unless %w{user agent master}.include?(arg)
    self.class.run_mode(arg.to_sym)
    set_run_mode self.class.run_mode
  end


  attr_accessor :interface, :type, :verb, :name, :arguments, :format

  def main
    @exit_code=0 
    # Call the method associated with the provided action (e.g., 'find').
    result = interface.send(verb, name, *arguments)
    if self.respond_to?(:render)
      puts render(verb, result)
    else 
      render_method = Puppet::Network::FormatHandler.format(format).render_method
      puts result.send(render_method) if result
    end
    exit(@exit_code)
  end

  def setup

    Puppet::Util::Log.newdestination :console

    @verb, @name, @arguments = command_line.args
    @arguments ||= []

    @type = self.class.name.to_s.sub(/.+:/, '').downcase.to_sym

    @interface = Puppet::Interface.interface(@type).new(@options)
    @format ||= @interface.class.default_format || :pson

    validate
  end

  def validate
    unless verb
      raise "You must specify #{interface.actions.join(", ")} as a verb; 'save' probably does not work right now"
    end

    unless interface.action?(verb)
      raise "Command '#{verb}' not found for #{type}"
    end
  end
end
