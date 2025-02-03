# frozen_string_literal: true

require 'spec_helper'

describe 'nft::object_impl' do
  let(:title) { 'NFT_OBJECT' }
  let(:params) do
    {
      'have_ipv4'     => true,
      'have_ipv6'     => false,
      'include_level' => 1,
      'ipv4_elements' => ['192.0.2.1'],
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_nft__file('005-objects') }
      it { is_expected.to contain_file('/etc/nftables/005-objects.nft') }
      it { is_expected.to contain_concat('nft::file::005-objects') }
      it { is_expected.to contain_concat__fragment('nft::fragment::chains/NFT_OBJECT') }
      it { is_expected.to contain_nft__fragment('chains/NFT_OBJECT') }
    end
  end
end
