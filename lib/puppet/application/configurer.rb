require 'puppet/application'
require 'puppet/faces'

class Puppet::Application::Configurer < Puppet::Application
  should_parse_config
  run_mode :agent

  option("--debug", "-d")
  option("--verbose", "-v")

  def setup
    if options[:debug] or options[:verbose]
      Puppet::Util::Log.level = options[:debug] ? :debug : :info
    end

    Puppet::Util::Log.newdestination(:console)
  end

  def run_command
    report = Puppet::Faces[:configurer, '0.0.1'].synchronize(Puppet[:certname])
    Puppet::Faces[:report, '0.0.1'].submit(report)
  end
end
