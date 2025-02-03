# frozen_string_literal: true

require 'spec_helper'

describe 'nft' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('Nft') }
      it { is_expected.to contain_exec('nft check') }
      [
        '/etc/.nftables-staging/main.conf',
        '/etc/.nftables-staging',
        '/etc/nftables',
      ].each { |file| it { is_expected.to contain_file(file) } }

      it { is_expected.to contain_package('nftables') }
      it { is_expected.to contain_service('nftables') }

      if os_facts.dig(:os, 'family') == 'RedHat'
        it { is_expected.to contain_file('/etc/sysconfig/nftables.conf') }
        it { is_expected.to contain_service('firewalld') }
      else
        it { is_expected.to contain_file('/etc/nftables.conf') }
      end
    end
  end
end
