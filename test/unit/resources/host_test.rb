# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Host' do

  it 'check host ping on ubuntu with dig' do
    resource = MockLoader.new(:ubuntu1404).load_resource('host', 'example.com')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host ping on centos 7' do
    resource = MockLoader.new(:centos7).load_resource('host', 'example.com')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host ping on darwin' do
    resource = MockLoader.new(:osx104).load_resource('host', 'example.com')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host ping on windows' do
    resource = MockLoader.new(:windows).load_resource('host', 'microsoft.com')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal false
    _(resource.ipaddress).must_equal ['134.170.185.46', '134.170.188.221']
  end

  it 'check host ping on unsupported os' do
    resource = MockLoader.new(:undefined).load_resource('host', 'example.com')
    _(resource.resolvable?).must_equal false
    _(resource.reachable?).must_equal false
    _(resource.ipaddress).must_be_nil
  end

  it 'check host tcp on ubuntu' do
    resource = MockLoader.new(:ubuntu1404).load_resource('host', 'example.com', port: 1234, protocol: 'tcp')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host tcp on centos 7' do
    resource = MockLoader.new(:centos7).load_resource('host', 'example.com', port: 1234, protocol: 'tcp')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host tcp on darwin' do
    resource = MockLoader.new(:osx104).load_resource('host', 'example.com', port: 1234, protocol: 'tcp')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ["2606:2800:220:1:248:1893:25c8:1946", "12.34.56.78"]
  end

  it 'check host tcp on windows' do
    resource = MockLoader.new(:windows).load_resource('host', 'microsoft.com', port: 1234, protocol: 'tcp')
    _(resource.resolvable?).must_equal true
    _(resource.reachable?).must_equal true
    _(resource.ipaddress).must_equal ['134.170.185.46', '134.170.188.221']
  end

  it 'check host tcp on unsupported os' do
    resource = MockLoader.new(:undefined).load_resource('host', 'example.com', port: 1234, protocol: 'tcp')
    _(resource.resolvable?).must_equal false
    _(resource.reachable?).must_equal false
    _(resource.ipaddress).must_be_nil
  end
end

describe Inspec::Resources::UnixHostProvider do
  describe '#resolve_with_dig' do
    let(:provider) { Inspec::Resources::UnixHostProvider.new(inspec) }
    let(:inspec)   { mock('inspec-backend') }
    let(:v4_command) { mock('v4_command') }
    let(:v6_command) { mock('v6_command') }

    it 'returns an array of IP addresses' do
      ipv4_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
12.34.56.78
EOL
      ipv6_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
2A03:2880:F112:83:FACE:B00C::25DE
EOL

      v4_command.stubs(:stdout).returns(ipv4_command_output)
      v6_command.stubs(:stdout).returns(ipv6_command_output)
      inspec.stubs(:command).with('dig +short AAAA testdomain.com').returns(v6_command)
      inspec.stubs(:command).with('dig +short A testdomain.com').returns(v4_command)
      provider.resolve_with_dig('testdomain.com').must_equal(['2A03:2880:F112:83:FACE:B00C::25DE', '12.34.56.78'])
    end

    it 'returns only v4 addresses if no v6 addresses are available' do
      ipv4_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
12.34.56.78
EOL
      ipv6_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
EOL

      v4_command.stubs(:stdout).returns(ipv4_command_output)
      v6_command.stubs(:stdout).returns(ipv6_command_output)
      inspec.stubs(:command).with('dig +short AAAA testdomain.com').returns(v6_command)
      inspec.stubs(:command).with('dig +short A testdomain.com').returns(v4_command)
      provider.resolve_with_dig('testdomain.com').must_equal(['12.34.56.78'])
    end

    it 'returns only v6 addresses if no v4 addresses are available' do
      ipv4_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
EOL
      ipv6_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
2A03:2880:F112:83:FACE:B00C::25DE
EOL

      v4_command.stubs(:stdout).returns(ipv4_command_output)
      v6_command.stubs(:stdout).returns(ipv6_command_output)
      inspec.stubs(:command).with('dig +short AAAA testdomain.com').returns(v6_command)
      inspec.stubs(:command).with('dig +short A testdomain.com').returns(v4_command)
      provider.resolve_with_dig('testdomain.com').must_equal(['2A03:2880:F112:83:FACE:B00C::25DE'])
    end

    it 'returns nil if no addresses are available' do
      ipv4_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
EOL
      ipv6_command_output = <<-EOL
a.cname.goes.here
another.cname.cool
EOL

      v4_command.stubs(:stdout).returns(ipv4_command_output)
      v6_command.stubs(:stdout).returns(ipv6_command_output)
      inspec.stubs(:command).with('dig +short AAAA testdomain.com').returns(v6_command)
      inspec.stubs(:command).with('dig +short A testdomain.com').returns(v4_command)
      provider.resolve_with_dig('testdomain.com').must_be_nil
    end
  end

  describe '#resolve_with_getent' do
    it 'returns an array of IP addresses when successful' do
      command_output = "2607:f8b0:4004:805::200e testdomain.com\n"
      command = mock('getent_command')
      command.stubs(:stdout).returns(command_output)
      command.stubs(:exit_status).returns(0)

      inspec = mock('inspec')
      inspec.stubs(:command).with('getent hosts testdomain.com').returns(command)

      provider = Inspec::Resources::LinuxHostProvider.new(inspec)
      provider.resolve_with_getent('testdomain.com').must_equal(['2607:f8b0:4004:805::200e'])
    end

    it 'returns nil if command is not successful' do
      command = mock('getent_command')
      command.stubs(:exit_status).returns(1)

      inspec = mock('inspec')
      inspec.stubs(:command).with('getent hosts testdomain.com').returns(command)

      provider = Inspec::Resources::LinuxHostProvider.new(inspec)
      provider.resolve_with_getent('testdomain.com').must_be_nil
    end
  end
end