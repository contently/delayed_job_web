require 'activerecord'
require 'delayed_job'
#require 'mongoid'
#require 'mysql'
require 'pg'

module DelayedJobWeb::LogParser
	#this is the module that reads through the DelayedJob logs

	#configure with a log path unix style OR look in Rails root for DJ log

	#Parse with request-log-analyzer plus custom logs if needed, format for nice stats and info in views
end