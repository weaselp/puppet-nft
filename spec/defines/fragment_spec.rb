# frozen_string_literal: true

require 'spec_helper'

describe 'nft::fragment' do
  let(:title) { 'swordfish' }
  let(:params) do
    {
      'content' => 'sword',
      'target'  => '001-test/inet/fish',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_concat__fragment('nft::fragment::swordfish') }
    end
  end
end
