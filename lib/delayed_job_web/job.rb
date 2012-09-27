require 'active_support'
require 'active_record'
require 'delayed_job'
require 'pg'

module DelayedJobWeb::Job << ActiveRecord::Base 
	include Delayed::Backend::Base

	# this is the actual Job obect class

	# Should be able to access either through 'database.rb' config or because in Rails app already

  #METHODS
  def description
    details = {}
    parsed_handler = self.handler.split(/\n/)
    parsed_handler.map{|x| details[x.split(":")[0].strip.split(/\//).last] = x.split(/\:|\/|\s/).last.strip unless x.blank?}
    target_class = details["ActiveRecord"]
    target_id = details["id"].to_s.gsub(/\W/,"").to_i if details["id"].present?
    performable_class = details["object"] if details["object"].present?
    performable_method = details["method_name"] if details["method_name"].present?
    return "Perform #{performable_class}:#{performable_method} on #{target_class}##{target_id}"
  end

  def queues
    delayed_job.select(:queue).map(&:queue).uniq.sort
  end

end