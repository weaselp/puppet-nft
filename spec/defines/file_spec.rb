# frozen_string_literal: true

require 'spec_helper'

describe 'nft::file' do
  let(:title) { 'eve' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_concat('nft::file::eve') }
      it { is_expected.to contain_file('/etc/nftables/eve.nft') }
    end
  end
end
