require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.before :each do
    Puppet[:strict] = :error
    Puppet[:strict_variables] = true
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

def tmpdir
  @tmpdir ||= Dir.mktmpdir('ext_file_line_test')
end

at_exit do
  FileUtils.remove_entry_secure(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
end
