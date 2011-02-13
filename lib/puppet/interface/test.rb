require 'puppet/interface/indirector'
require 'find'
# inherits from interface b/c they is no indirector
class Puppet::Interface::Test < Puppet::Interface

  # check for any tests that may be missing
  action(:check_tests) do |args|
    code = get_code(@modulepath)
    missing_tests = code[:untested].each do |name|
      Puppet.warning("#{name} is missing tests")
    end.size
    exit(missing_tests)
  end


  # compile any tests that may be missing
  action(:compile_tests) do |args|
    code = get_code(@modulepath)
    results = compile_module_tests(code[:tests], @run_noop)
    exit_code = results.include?('failed') ? 1 : 0
    exit(exit_code)
  end

  # overriding initialize just so that I can handle some options
  def initialize(opts={})
    @env = Puppet::Node::Environment.new(Puppet[:environment])
    @run_noop = opts[:run_noop]
    @modulepath = opts[:modulepath] || @env[:modulepath]
    Puppet[:modulepath] = @modulepath
    puts @modulepath
    self.class.load_actions
  end

  #  given a modulepath, returns all of the manifests and test manifests
  #  and manifests without corresponding tests
  def get_code(modulepath)
    code = {:tests => [], :untested => [], :manifests => []}
    tests, manifests = [],[]
    modulepath.split(':').each do |path|
      path.gsub!(/\/$/, '')
      Puppet.info("Searching modulepath: #{path}")
      # TODO - this does not find symlinks
      Find.find(path) do |file|
        if file =~ /#{path}\/(\S+)\/tests\/(\S+.pp)$/
          code[:tests].push file
          tests.push "#{$1}-#{$2.gsub('/', '-')}"
        elsif file =~ /#{path}\/(\S+)\/manifests\/(\S+.pp)$/
          code[:manifests].push file
          manifests.push "#{$1}-#{$2.gsub('/', '-')}"
        end
      end
    end
    code[:untested] = manifests-tests
    code
  end

  # set the testfile as the manifest and the node name
  def compile_module_tests(testfiles, run_noop=false)
    # TODO - I should be able to pick any fact cache
    testfiles.collect do |test|
      Puppet[:manifest]=test
      # convert manifests into a readable minimal name that is unique
      node_name = test.gsub('/', '-').gsub(/.*?-tests-/, '')
      cat_interface = Puppet::Interface.interface(:catalog).new()
      catalog = cat_interface.compile_from_node(node_name, :ignore_cache=>true)
      if run_noop and catalog
        noop_run(catalog).status
      else 
        # return failed if catalog is nil
        catalog || 'failed'
      end
    end
  end

  # given a catalog, run it in noop mode
  def noop_run(catalog)
    catalog = catalog.to_ral
    Puppet[:noop] = true
    require 'puppet/configurer'
    configurer = Puppet::Configurer.new
    begin
      Puppet[:pluginsync] = false
      status = configurer.run(:catalog => catalog)
    rescue
      Puppet.err("Exception when noop running catalog #{$!}")
    end
  end
  
end
