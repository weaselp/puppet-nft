# frozen_string_literal: true

require 'spec_helper'

describe 'nft::chain' do
  let(:title) { 'dave' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_nft__file('010-chains') }
      it { is_expected.to contain_nft__file('050-rules/inet/filter/dave') }
      it { is_expected.to contain_file('/etc/nftables/010-chains.nft') }
      it { is_expected.to contain_file('/etc/nftables/050-rules_inet_filter_dave.nft') }
      it { is_expected.to contain_concat('nft::file::010-chains') }
      it { is_expected.to contain_concat('nft::file::050-rules_inet_filter_dave') }

      it { is_expected.to contain_concat__fragment('nft::fragment::chains/inet/filter/dave') }
      it { is_expected.to contain_nft__fragment('chains/inet/filter/dave') }
    end
  end
end
