module Items
  class UpsyncService
    def initialize(item)
      @item = item
    end

    def call
      unless @item.syncable?
        Rails.logger.warn "#{self.class.to_s} - id: #{@item.id} is not allowed to sync"
        return
      end

      if @item.guid.blank?
        create_item
      else
        update_item
      end
      true
    rescue => error
      Bugsnag.notify(error)
      Rails.logger.error "#{self.class.to_s} - #{error.message}"
      false
    end

    private

    def create_item
      remote_item = assign_attributes(RemoteSource::Item.new)
      guid = remote_item.save
      @item.update_columns(guid: guid)
    end

    def update_item
      assign_attributes(RemoteSource::item.find(@item.guid)).save
    end

    def assign_attributes(remote_item)
      remote_item.name = @item.name
      remote_item.email = @item.email
      remote_item.currency = @item.currency.try(:code)
      remote_item
    end
  end
end
