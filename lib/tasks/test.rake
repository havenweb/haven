# frozen_string_literal: true

Rake::Task['test'].clear if Rake::Task.task_defined?('test')

task test: :environment do
  sh 'bin/rails test:all'
end
