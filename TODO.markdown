Remaining Tasks
==================

Completely seperate the DelayedJob methods and the sinatra app.

1. Make work as stand alone app
    1. Add database.yml file in app directory to run as stand alone
    2. Ensure can use any database type, including Mongo
    3. Add script in root to run as stand alone
    4. Add check to see if running as Gem or Sinatra App (i.e. "Where am I running from? Is Sinatra running?")
2. Make work as Gem that can read remote databases
    1. Add initializer to point to db path (use local as default) so can read
3. Add PID/Daemon monitoring for Delayed Job Deamon
    1. Ruby lib to see running procs (even on multiple machines)
    2. Ability to restart jobs if not running
4. Ability to edit jobs on the fly, individually or in bulk
    1. Change PID, queue, run_at
5. Delayed Jobs statistics and processing numbers
	1. Store jobs total and jobs per second will app is running, maybe store in YAML?
	2. Use request-log-analyzer for past dj stats