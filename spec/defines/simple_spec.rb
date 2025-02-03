# frozen_string_literal: true

require 'spec_helper'

describe 'nft::simple' do
  let(:title) { 'alice' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_nft__rule('alice') }
      it { is_expected.to contain_nft__fragment('alice') }
      it { is_expected.to contain_concat__fragment('nft::fragment::alice') }
    end
  end
end
