require 'active_support'
require 'active_record'
require 'pg'

module DelayedJobWeb::Database
	#this is the module that loads the database

	#look for a config.yml in the root path with changed values, if exists, map connection to it and warn/fail if error

	#if database.yml is default, try to see if loaded as part of a Rails app (i.e. GEM MODE)

	#DO SOMETHING LIKE THIS TO LOAD THE DB
	#  ActiveRecord::Base.establish_connection(YAML.load(File.read(File.join('config','database.yml')))[ENV['ENV'] ? ENV['ENV'] : 'development'])
end