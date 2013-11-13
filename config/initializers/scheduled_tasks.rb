require 'rufus-scheduler'

# This task ensures that any records locked for more than five minutes (probably
# a stale record) get unlocked.
remove_stale_locks = Rufus::Scheduler.new

remove_stale_locks.every("5m") do
  LockedObject.where("created_at >= ?", 5.minutes.ago).delete_all
end