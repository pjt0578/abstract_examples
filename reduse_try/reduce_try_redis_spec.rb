require 'rails_helper'

describe ReduceTryRedis do
  let(:key){"#{rand(9999)}_#{Time.now.to_i}"}

  subject {ReduceTryRedis.new(key)}

  it 'try once' do
    expect(subject.check(count: 1, time: 5.minutes)).to be true
    expect(subject.check(count: 1, time: 5.minutes)).to be false
  end

  it 'try few time' do
    5.times do |i|
      expect(subject.check(count: 5, time: 5.minutes)).to be true
    end

    expect(subject.check(count: 5, time: 5.minutes)).to be false
  end

  it 'clear work fine' do
    expect(subject.check(count: 1, time: 5.minutes)).to be true
    expect(subject.check(count: 1, time: 5.minutes)).to be false

    subject.clear

    expect(subject.check(count: 1, time: 5.minutes)).to be true
  end

  it 'set correct expire key' do
    subject.check(count: 5, time: 5.minutes)
    expect(subject.expire <= 5.minutes.to_i).to be true
  end
end