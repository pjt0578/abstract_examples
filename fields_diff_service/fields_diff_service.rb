class Meta::FieldsDiffService

  def call
    staging = fetch_db(Field::NAME_STAGING)
    prod = fetch_db(Field::NAME_PROD)

    find_diff(staging, prod)
  end

  def fetch_db(environment)
    query = "
    WITH extracted AS (
      SELECT
          id,
          environment,
          field,
          batch_key,
          data,
          row_number() OVER (PARTITION BY field ORDER BY batch_key DESC) AS rating_in_section
      FROM fields
      WHERE environment = '#{environment}'
      ORDER BY id
    )
    SELECT field, data FROM extracted WHERE rating_in_section = 1
    "

    out = {}
    ActiveRecord::Base.connection.execute(query).to_a.each do |data|
      out[data['field']] = JSON.parse(data['data'])
    end

    out
  end

  private

  def find_diff(staging, prod)
    all_data = {}

    if staging.blank? || prod.blank?
      all_data['missing_staging'] = staging.blank?
      all_data['missing_prod'] = prod.blank?
      return all_data
    end

    Field::FIELDS.each do |key|
      staging_field_data = staging[key].presence || {}
      prod_field_data = prod[key].presence || {}

      next if staging_field_data.blank? && prod_field_data.blank?

      all_data[key] ||= {}

      all_data[key]['stg_prd'] = staging_field_data.keys - prod_field_data.keys
      all_data[key]['prd_stg'] = prod_field_data.keys - staging_field_data.keys

      (prod_field_data.keys & staging_field_data.keys).each do |same_key|

        except_prod_key = prod_field_data[same_key].keys.select { |current_key| prod_field_data[same_key][current_key].is_a?(Array) }
        except_stag_key = staging_field_data[same_key].keys.select { |current_key| staging_field_data[same_key][current_key].is_a?(Array) }

        prod_data = prod_field_data[same_key].except(*except_prod_key)
        staging_data = staging_field_data[same_key].except(*except_stag_key)

        prod_data.each { |k, v| prod_data[k] = v == "true" ? true : v == "false" ? false : v }
        staging_data.each { |k, v| staging_data[k] = v == "true" ? true : v == "false" ? false : v }

        next if (prod_data.to_a - staging_data.to_a).blank?

        Hash[*(prod_data.to_a - staging_data.to_a).flatten].keys.each do |diff_key|
          all_data[key]['diff'] ||= {}
          all_data[key]['diff'][same_key] ||= {}
          all_data[key]['diff'][same_key][diff_key] ||= {}
          all_data[key]['diff'][same_key][diff_key][Field::NAME_PROD] = prod_data[diff_key]
          all_data[key]['diff'][same_key][diff_key][Field::NAME_STAGING] = staging_data[diff_key]
        end
      end
    end

    all_data
  end
end