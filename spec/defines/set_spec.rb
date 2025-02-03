# frozen_string_literal: true

require 'spec_helper'

describe 'nft::set' do
  let(:title) { 'setname' }
  let(:params) do
    {
      'type' => 'ipv4_addr',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_nft__file('005-sets/inet/filter') }
      it { is_expected.to contain_file('/etc/nftables/005-sets_inet_filter.nft') }
      it { is_expected.to contain_concat('nft::file::005-sets_inet_filter') }
      it { is_expected.to contain_concat__fragment('nft::fragment::sets/inet/filter/setname') }
      it { is_expected.to contain_nft__fragment('sets/inet/filter/setname') }
    end
  end
end
