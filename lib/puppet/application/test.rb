require 'puppet/application/data_baseclass'

class Puppet::Application::Test < Puppet::Application::DataBaseclass
  run_mode :master
  option('--modulepath PATH') do |args|
    options[:modulepath]=args
  end
  option('--outputdir DIR') do |args|
    options[:outputdir]=args
  end
  option('--run_noop')

  # there must be a better way to do this
  def setup 

    Puppet::Util::Log.newdestination :console

    @verb, @name, @arguments = command_line.args
    @arguments ||= []

    @type = self.class.name.to_s.sub(/.+:/, '').downcase.to_sym

    @interface = Puppet::Interface.interface(@type).new(options)
    @format ||= @interface.class.default_format || :pson

    validate
    # NOTE - maybe I should move this to Base
  end
end
