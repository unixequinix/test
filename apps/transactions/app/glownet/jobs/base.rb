class Jobs::Base < ActiveJob::Base
  def self.write(atts)
    klass = "#{atts[:transaction_category]}_transaction".classify.constantize
    column_names = klass.column_names
    obj_atts = atts.dup.keep_if { |k, _| column_names.include? k.to_s }
    obj = klass.find_or_create(obj_atts)
    workers = descendants.select { |w| w::TYPES.include? atts[:transaction_type] }
    workers.each { |worker|  worker.perform_later(atts.merge(transaction_id: obj.id)) }
    obj
  end

  def self.inherited(klass)
    @descendants ||= []
    @descendants << klass
  end

  def self.descendants
    @descendants || []
  end
end
