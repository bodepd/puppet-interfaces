require 'puppet/interface/indirector'

class Puppet::Interface::Catalog < Puppet::Interface::Indirector
  # this name is less than ideal
  # this action is for taking some list of 
  # nodes from yaml and compiling catalogs for them
  # TODO - where are the catalogs stored?
  action(:batch_compile) do |args|
    get_nodes(args).each do |node|
      compile_from_node(node)
    end
  end

  # get the existing nodes that have been serialized in yaml
  # always returns an array
  def get_nodes(node_name, terminus='yaml')
    interface = Puppet::Interface.interface(:node).new
    interface.set_terminus(terminus)
    if node_name.include?('*')
      interface.search(node_name)
    else
      [interface.find(node_name)]
    end
  end

  # compile a catalog from a node's yaml
  def compile_from_node(node_name, opts={})
    begin
      # interface = Puppet::Interface.interface(:catalog).new()
      # TODO - I need to pass a node so that I can set the environment
      # caching to yaml after compilation, but ignoring the cache
      self.class.indirection.cache_class = :yaml
      catalog = find(node_name, :ignore_cache=>true)
      Puppet.debug "Compile test results: #{catalog.render(:pson)}"
      catalog
    rescue
      Puppet.warning("Node #{node_name} could not compile: #{$!}")
      return false
    end
  end
end
