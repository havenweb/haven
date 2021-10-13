# Schedule hourly fetch for updating RSS/Atom feeds
minute = (rand*59).to_i.to_s
cron_line = "#{minute} * * * * bash -i -c '/var/www/haven/bin/rails r UpdateFeedJob.perform_now'"

# Append to existing crontab
`crontab -l > /tmp/my.cron`
`echo "#{cron_line}" >> /tmp/my.cron`
`crontab < /tmp/my.cron`
