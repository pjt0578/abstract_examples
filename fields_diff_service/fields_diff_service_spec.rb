require 'rails_helper'

describe Meta::FieldsDiffService do
  let(:correct_data) do
    {
        "Field_1" => {
            "stg_prd" => ["key4_staging"],
            "prd_stg" => ["key4_production"],
            "diff" => {
                "key3" => { "sub_key3" => { "production" => "sub_value3_production", "staging" => "sub_value3_staging" } }
            }
        },
        "Field_2" => {
            "stg_prd" => ["key4_staging"],
            "prd_stg" => ["key4_production"],
            "diff" => {
                "key3" => { "sub_key3" => { "production" => "sub_value3_production", "staging" => "sub_value3_staging" } }
            }
        }
    }

  end

  before do
    [Field::NAME_STAGING, Field::NAME_PROD].each do |environment|
      batch_key = Time.now.utc.to_f
      Field::FIELDS.each do |field_name|
        value = {
            key1: { sub_key1: 'sub_value1' },
            key2: { sub_key2: 'sub_value2' },
            key3: { sub_key3: "sub_value3_#{environment}" },
            :"key4_#{environment}" => { sub_key4: 'sub_value4' },
        }
        Field.create!({ environment: environment, field: field_name, batch_key: batch_key, data: value })
      end
    end
  end

  subject { described_class.new }

  it 'doesn\'t raise error' do
    expect { subject.call }.to_not raise_exception
  end

  it 'return correct data' do
    expect(subject.call).to eq(correct_data)
  end
end