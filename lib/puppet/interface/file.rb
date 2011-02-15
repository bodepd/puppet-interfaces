require 'puppet/interface/indirector'

Puppet::Interface::Indirector.new(:file) do
  def self.indirection_name
    :file_bucket_file
  end
end
