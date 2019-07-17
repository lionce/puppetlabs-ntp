require 'spec_helper_acceptance'

case os[:family]
when 'redhat', 'freebsd', 'linux'
  servicename = 'ntpd'
else
  servicename = if os[:family] == 'sles' && os[:release].start_with?('12', '15')
                  'ntpd'
                else
                  'ntp'
                end
end

config = if os[:family] == 'redhat'
           "/etc/sysconfig/#{servicename}"
         else
           "/etc/default/#{servicename}"
         end

puts os[:family]
describe 'ntp class with daemon options:', unless: UNSUPPORTED_PLATFORMS.include?(os[:family]) do
  let(:pp) do
    "class { 'ntp':
    service_enable => true,
    service_ensure => running,
    service_manage => true,
    service_name   => '#{servicename}',
    user => 'ntp',
    daemon_extra_opts => '-g -i /var/lib/ntp' }"
  end

  it 'run module twice idempotently' do
    idempotent_apply(pp)
  end

  describe file(config.to_s) do
    its(:content) { is_expected.to match(%r{(OPTIONS|NTPD_OPTS)='-g -i \/var\/lib\/ntp'}) }
  end

  if os[:family] == 'redhat'
    describe file('/etc/systemd/system/multi-user.target.wants/ntpd.service') do
      its(:content) { is_expected.to match(%r{ntpd -u ntp:ntp}) }
    end
  end
  if os[:family] == 'debian'
    describe file('/usr/lib/ntp/ntp-systemd-wrapper') do
      its(:content) { is_expected.to match(%r{RUNASUSER=ntp}) }
    end
  end
end
