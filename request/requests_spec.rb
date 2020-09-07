require 'rails_helper'

describe Stats::Request do
  let(:config) do
    {
        tables:
            [
                { table: 'test_table_1', local_field: 'local_field_1' },
                { table: 'test_table_2', sort_field: 'sort_field_2', data_field: 'data_field_2', local_field: 'local_field_2' }
            ],
        group_field: "group_field_test",
        connect: {
            host: "127.0.0.1", port: 5432, database: "database_test", username: "postgres", password: "1234"
        }
    }
  end
  subject { described_class.new(config) }
  let(:conn) { double('conn', connect: {}, conn: {}) }

  before do
    allow(PG::Connection).to receive(:connect) { conn }
    allow(conn).to receive(:exec) { {} }
  end

  it 'make connect to remote database' do
    expect(PG::Connection).to receive(:connect).with("127.0.0.1", 5432, "", "", "database_test", "postgres", "1234") { conn }
    subject.call
  end

  it 'parse response' do
    allow(conn).to receive(:exec) { [{ "id" => "4234", "value" => "n1" }, { "id" => "12345", "value" => "b2" }] }
    expect(subject.call).to eq({
                                   "4234" => { "local_field_1" => "n1", "local_field_2" => "n1" },
                                   "12345" => { "local_field_1" => "b2", "local_field_2" => "b2" }
                               })
  end
end
