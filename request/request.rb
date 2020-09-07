require 'pg'

class Stats::Request

  def initialize(config)
    @tables = config[:tables]
    @group_field = config[:group_field]
    @connect = config[:connect]
  end

  def call(write_to_file: false,  file_name: nil)
    result = {}

    # can be useful for debug
    if file_name.present?
      File.open("#{Rails.root}/#{file_name}", 'r') do |file|
        result = JSON.parse(file.read)
      end
    else
      if @connect[:host].blank?
        Rails.logger.error "#{self.class.to_s} host is blank}"
        return {}
      end

      result = get_db_data
      write_to_file(result) if write_to_file
    end

    Rails.logger.info "#{self.class.to_s} Receive: #{result.keys.count}"
    result
  end

  private

  def get_db_data
    @conn = PGconn.connect(@connect[:host], @connect[:port], '', '', @connect[:database], @connect[:username], @connect[:password])
    @conn.exec("set search_path=#{@connect[:schema_search_path]};") if @connect[:schema_search_path].present?

    result = {}
    @tables.each do |data|
      field = data[:local_field]
      make_request(data, @group_field).each do |row|
        id = row["id"]
        result[id] ||= {}
        result[id][field] = row["value"]
      end
    end
    result
  end

  def make_request(data, group_field)
    if data[:data_field].present?
      @conn.exec(
          "
            WITH extracted AS (
              SELECT t.*, first_value(#{data[:data_field]}) OVER (PARTITION BY #{group_field} ORDER BY #{data[:sort_field]} DESC) AS first_item
              FROM #{data[:table]} AS t
            )
            SELECT #{group_field} AS id, first_item AS value FROM extracted WHERE #{group_field} IS NOT NULL AND #{group_field} <> '' GROUP BY #{group_field}, first_item;
          ".split("\n").join(' ').gsub(/ +/, ' ')
      )
    else
      @conn.exec("SELECT COUNT(*) AS value, #{group_field} AS id FROM #{data[:table]} WHERE #{group_field} IS NOT NULL AND #{group_field} <> '' GROUP BY #{group_field}")
    end
  end

  # can be useful for debug
  def write_to_file(result)
    File.open("#{Rails.root}/stat_#{Time.now.to_s}", 'w+') do |file|
      file << result.to_json
    end
  end
end