require 'rails_helper'

RSpec.describe Items::UpsyncService do
  let(:item_guid) { 'item_guid' }
  let(:currency) { create :currency, code: 'USD'}
  let(:target_item) do
    Item.create!(
        name: "item_name",
        email: "email@email.com",
        currency_id: currency.id,
        guid: item_guid
    )
  end

  let(:correct) do
    {
        email: "email@email.com",
        name: "item_name",
        currency: "USD"
    }
  end

  subject { Items::UpsyncService.new(target_item).call }

  before do
    allow_any_instance_of(RemoteSource::Item).to receive(:save).and_return(item_guid)
    allow(RemoteSource::Item).to receive(:find) { RemoteSource::Item.new({ id: item_guid }) }
    allow(target_item).to receive(:syncable?).and_return(true)
  end

  context '#when has no item_guid' do
    let(:item_guid) { nil }

    it 'set guid' do
      expect { subject; target_item.reload }.to change { target_item.item_guid }.from(nil).to(item_guid)
    end
  end

  it 'halt if item not syncable' do
    allow(target_item).to receive(:syncable?).and_return(false)
    expect(subject).to be_blank
  end

  it 'create an account if item is syncable' do
    allow(target_item).to receive(:update_columns).and_return(true)
    expect(subject).not_to be_blank
  end

  it 'work without error' do
    expect(Bugsnag).to_not receive(:notify)
    subject
  end

  it 'set correct value to remote' do
    remote_item = RemoteSource::Item.new
    Items::UpsyncService.new(target_item).send(:assign_attributes, remote_item)

    params = {}
    remote_item.attributes.each do |attr|
      params[attr] = remote_item.send(attr)
    end

    expect(params.slice(*correct.keys)).to eq(correct)
  end
end
