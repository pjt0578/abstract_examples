class ReduceTryRedis
  def initialize(id)
    @key = "redis_reduce_try_#{id}"
  end

  def check(count:, time:)
    Sidekiq.redis do |redis|
      result = redis.incr(@key).to_i
      redis.expire(@key, time.to_i) if result <= 1
      return result <= count
    end
  end

  def expire
    Sidekiq.redis do |redis|
      return redis.ttl(@key)
    end
  end

  def clear
    Sidekiq.redis do |redis|
      return redis.del(@key)
    end
  end

  def value
    Sidekiq.redis do |redis|
      return redis.get(@key).to_i
    end
  end

  # example of usage
  # reducer = ReduceTryRedis.new("mark_#{mark}")
  # if reducer.check(count: 2, time: 1.minutes)
  #   SomeService.new(
  #     param1: param1,
  #     param2: param1
  #   ).call
  #   true
  # else
  #   Rails.logger.warn "#{self.class.name} frequent update: #{id} reduce multiple calls #{reducer.value}"
  #   false
  # end

end