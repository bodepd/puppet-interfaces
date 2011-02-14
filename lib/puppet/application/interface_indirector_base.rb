require 'puppet/application'
require 'puppet/application/interface_base'
require 'puppet/interface'

# base application for all interfaces that are also terminuses
class Puppet::Application::InterfaceIndirectorBase < Puppet::Application::InterfaceBase

  option("--from TERMINUS", "-f") do |arg|
    @from = arg
  end

  # XXX this doesn't work, I think
  # NOTE - this probably beongs in InterfaceIndirectorBase (and needs to list
  # actions instead of termini)
  option("--list") do
    indirections.each do |ind|
      begin
        classes = terminus_classes(ind.to_sym)
      rescue => detail
        $stderr.puts "Could not load terminuses for #{ind}: #{detail}"
        next
      end
      puts "%-30s: #{classes.join(", ")}" % ind
    end
    exit(0)
  end

  attr_accessor :from, :indirection

  def setup

    super

    raise "Could not find data type #{type} for application #{self.class.name}" unless interface.indirection

    @interface.set_terminus(from) if from
  end

end
