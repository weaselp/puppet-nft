# frozen_string_literal: true

require 'spec_helper'

describe 'nft::rule' do
  let(:title) { 'bob' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_nft__fragment('bob') }
      it { is_expected.to contain_concat__fragment('nft::fragment::bob') }
    end
  end
end
