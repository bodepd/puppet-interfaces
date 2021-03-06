Puppet Strings
=================
A set of executables that provide complete CLI access to Puppet's
core data types.  They also provide String classes for
each of the core data types, which are extensible via plugins.

For instance, you can create a new action for catalogs at
lib/puppet/string/catalog/$action.rb.

This is a Puppet module and should work fine if you install it
in Puppet's module path.

**Note that this only works with Puppet 2.6.next (and thus will work
with 2.6.5), because there is otherwise a bug in finding Puppet applications.
You also have to either install the lib files into your Puppet libdir, or
you need to add this lib directory to your RUBYLIB.**

This is meant to be tested and iterated upon, with the plan that it will be
merged into Puppet core once we're satisfied with it.

Usage
-----
The general usage is:

    $ puppet <string> <verb> <name>

So, e.g.:

    $ puppet facts find myhost.domain.com
    $ puppet node destroy myhost

You can use it to list all known data types and the available terminus classes:

    $ puppet string list
    catalog                       : active_record, compiler, queue, rest, yaml
    certificate                   : ca, file, rest
    certificate_request           : ca, file, rest
    certificate_revocation_list   : ca, file, rest
    file_bucket_file              : file, rest
    inventory                     : yaml
    key                           : ca, file
    node                          : active_record, exec, ldap, memory, plain, rest, yaml
    report                        : processor, rest, yaml
    resource                      : ral, rest
    resource_type                 : parser, rest
    status                        : local, rest

But most interestingly, you can use it for two main purposes:

* As a client for any Puppet REST server, such as catalogs, facts, reports, etc.
* As a local CLI for any local Puppet data

A simple case is looking at the local facts:

    $ puppet facts find localhost

If you're on the server, you can look in that server's fact collection:

    $ puppet facts --mode master --vardir /tmp/foo --terminus yaml find localhost

Note that we're setting both the vardir and the 'mode', which switches from the default 'agent' mode to server mode (requires a patch in my branch).

If you'd prefer the data be outputted in json instead of yaml, well, you can do that, too:

    $ puppet find --mode master facts --vardir /tmp/foo --terminus yaml --format pson localhost

To test using it as an endpoint for compiling and retrieving catalogs from a remote server, (from my commit), try this:

    # Terminal 1
    $ sbin/puppetmasterd --trace --confdir /tmp/foo --vardir /tmp/foo --debug --manifest ~/bin/test.pp --certname localhost --no-daemonize
    
    # Terminal 2
    $ sbin/puppetd --trace --debug --confdir /tmp/foo --vardir /tmp/foo --certname localhost --server localhost --test --report
    
    # Terminal 3, actual testing
    $ puppet catalog find localhost --certname localhost --server localhost --mode master --confdir /tmp/foo --vardir /tmp/foo --trace --terminus rest

This compiles a test catalog (assuming that ~/bin/test.pp exists) and returns it.  With the right auth setup, you can also get facts:

    $ puppet facts find localhost --certname localhost --server localhost --mode master --confdir /tmp/foo --vardir /tmp/foo --trace --terminus rest

Or use IRB to do the same thing:

    $ irb
    >> require 'puppet/string'
    => true
    >> string = Puppet::String[:facts, '1.0.0']
    => #<Puppet::String::Facts:0x1024a1390 @format=:yaml>
    >> facts = string.find("myhost")

Like I said, a prototype, but I'd love it if people would play it with some and make some recommendations.

Extending
---------
Like most parts of Puppet, these are easy to extend.  Just drop a new action into a given string's directory.  E.g.:

    $ cat lib/puppet/string/catalog/select.rb 
    # Select and show a list of resources of a given type.
    Puppet::String.define(:catalog, '1.0.0') do
      action :select do
        invoke do |host,type|
          catalog = Puppet::Resource::Catalog.indirection.find(host)

          catalog.resources.reject { |res| res.type != type }.each { |res| puts res }
        end
      end
    end
    $ puppet catalog select localhost Class
    Class[main]
    Class[Settings]
    $

Notice that this gets loaded automatically when you try to use it.  So, if you have a simple command you've written, such as for cleaning up nodes or diffing catalogs, you an port it to this framework and it should fit cleanly.

Also note that strings are versioned.  These version numbers are interpreted according to Semantic Versioning (http://semver.org).
