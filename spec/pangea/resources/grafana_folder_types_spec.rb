# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::Grafana::Types::FolderAttributes do
  describe 'required attributes' do
    it 'requires title' do
      expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
    end

    it 'accepts title as a string' do
      attrs = described_class.new(title: 'My Folder')
      expect(attrs.title).to eq('My Folder')
    end

    it 'rejects non-string title' do
      expect { described_class.new(title: 42) }.to raise_error(Dry::Struct::Error)
    end
  end

  describe 'optional attributes' do
    let(:base) { { title: 'Folder' } }

    it 'defaults uid to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:uid)
    end

    it 'accepts uid as a string' do
      attrs = described_class.new(base.merge(uid: 'folder-uid'))
      expect(attrs.uid).to eq('folder-uid')
    end

    it 'accepts uid as nil' do
      attrs = described_class.new(base.merge(uid: nil))
      expect(attrs.uid).to be_nil
    end

    it 'defaults parent_folder_uid to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:parent_folder_uid)
    end

    it 'accepts parent_folder_uid as a string' do
      attrs = described_class.new(base.merge(parent_folder_uid: 'parent-uid'))
      expect(attrs.parent_folder_uid).to eq('parent-uid')
    end
  end

  describe 'transform_keys' do
    it 'converts string keys to symbols' do
      attrs = described_class.new('title' => 'Test Folder')
      expect(attrs.title).to eq('Test Folder')
    end
  end
end
