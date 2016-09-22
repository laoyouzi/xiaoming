env = Env["RAILS_ENV"] || "development"
APP_PORT ||= ENV['APP_PORT']i || 3000

worker_processes 4

app_dir = File.expand_path("../..", __FILE__)

app_name = "first_test"

pid_path = "#{app_dir}/tmp/pids/unicorn.#{app_name}.pid"

sock_path = "#{app_dir}/tmp/sockets/unicorn.#{app_name}.sock"

listen sock_path, :backlog => 64

timeout 30

pid pid_path

listen APP_PORT, :tcp_nopush => true

if env == "production"
  working_directory "#{app_dir}/current"

  user 'deploy', 'deploy'
  shared_path = "#{app_dir}/current/shared"

  stderr_path "#{shared_path}/log/unicorn.stderr.log"
  stdout_path "#{shared_path}/log/unicorn.stdout.log"
end

preload_app true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_dir}/Gemfile"
end

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "#{pid_path}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

end

