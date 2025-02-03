# frozen_string_literal: true

require 'spec_helper'

describe 'nft::object' do
  let(:title) { 'NFT_OBJECT' }
  let(:params) do
    {
      'elements' => ['192.0.2.1'],
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
