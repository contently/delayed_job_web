require 'sinatra'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'active_support'
require 'active_record'
require 'delayed_job'
require 'haml'
require 'pg'

# Need to specify this in a YAML config somewhere
# We want to be able to access jobs remotely/seperate from main app.
class Delayed_Job < ActiveRecord::Base
  include Delayed::Backend::Base
  set :database, 'postgresql:///contently'

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
end

class DelayedJobWeb < Sinatra::Base
  set :database, 'postgresql:///contently'
  set :root, File.dirname(__FILE__)
  set :static, true
  set :public_folder,  File.expand_path('../public', __FILE__)
  set :views,  File.expand_path('../views', __FILE__)
  set :haml, { :format => :html5 }
  register Sinatra::ActiveRecordExtension
 
  #Set in YAML file and pass in here via ENV variables?
  DB_PATH = ""
  RAILS_APP_PATH = ""
  RAILS_LOG_PATH = ""

  def current_page
    url_path request.path_info.sub('/','')
  end

  def start
    params[:start].to_i
  end

  def per_page
    25
  end

  def url_path(*path_parts)
    [ path_prefix, path_parts ].join("/").squeeze('/')
  end
  alias_method :u, :url_path

  def path_prefix
    request.env['SCRIPT_NAME']
  end

  def delayed_job
    begin
      Delayed_Job
    rescue
      false
    end
  end

  get '/overview' do
    if delayed_job
      haml :overview
    else
      @message = "Unable to connected to Delayed::Job database"
      haml :error
    end
  end

  get '/stats' do
    haml :stats
  end

  def tabs
    [
      {:name => 'Overview', :path => '/overview'},
      {:name => 'Enqueued', :path => '/enqueued'},
      {:name => 'Working', :path => '/working'},
      {:name => 'Pending', :path => '/pending'},
      {:name => 'Failed', :path => '/failed'},
      {:name => 'Stats', :path => '/stats'}
    ]
  end

  #Static Page Rendering
  %w(enqueued working pending failed).each do |page|
    get "/#{page}" do
      @jobs = delayed_jobs(page.to_sym).order('created_at desc, id desc').offset(start).limit(per_page)
      @all_jobs = delayed_jobs(page.to_sym)
      haml page.to_sym
    end
  end

  #Polling Page Rendering
  %w(overview enqueued working pending failed stats) .each do |page|
    get "/#{page}.poll" do
      show_for_polling(page)
    end

    get "/#{page}/:id.poll" do
      show_for_polling(page)
    end
  end

  def queues
    delayed_job.select(:queue).map(&:queue).uniq.sort
  end

  get "/queue/:queue" do
    @jobs = delayed_job.where(:queue=>params[:queue]).order('created_at desc, id desc').offset(start).limit(per_page)
    @all_jobs = delayed_job.where(:queue=>params[:queue]).count
    haml :queue
  end

  def delayed_jobs(type)
    delayed_job.where(delayed_job_sql(type))
  end

  def delayed_job_sql(type)
    case type
    when :enqueued
      ''
    when :working
      'locked_at is not null'
    when :failed
      'last_error is not null'
    when :pending
      'attempts = 0'
    end
  end

  get "/?" do
    redirect u(:overview)
  end

  def partial(template, local_vars = {})
    @partial = true
    haml(template.to_sym, {:layout => false}, local_vars)
  ensure
    @partial = false
  end

  def poll
    if @polling
      text = "Last Updated: #{Time.now.strftime("%H:%M:%S")}"
    else
      text = "<a href='#{u(request.path_info)}.poll' rel='poll'>Live Poll</a>"
    end
    "<p class='poll'>#{text}</p>"
  end

  def show_for_polling(page)
    content_type "text/html"
    @polling = true
    # show(page.to_sym, false).gsub(/\s{1,}/, ' ')
    @jobs = delayed_jobs(page.to_sym)
    haml(page.to_sym, {:layout => false})
  end

  ################################## ACTIONS ################################
  get "/remove/:id" do
    delayed_job.find(params[:id]).delete
    redirect back
  end

  get "/requeue/:id" do
    job = delayed_job.find(params[:id])
    job.update_attributes(:run_at =>Time.now,:failed_at=>nil,:locked_at=>nil,:attempts=>0)
    redirect back
  end

  post "/failed/clear" do
    delayed_job.where("last_error IS NOT NULL").destroy_all
    redirect back
  end

  post "/requeue/all" do
    delayed_job.where("last_error IS NOT NULL").update_all(
      :run_at=>Time.now,
      :failed_at => nil,
      :attempts=>0,
      :last_error=>nil,
      :locked_at=>nil)
    redirect back
  end

  get '/update/:id' do
    "#{params[:id]}"
  end

  post '/update/all' do
    "#{params}"
  end
  ############################################################################

end

# Run the app!
DelayedJobWeb.run!
