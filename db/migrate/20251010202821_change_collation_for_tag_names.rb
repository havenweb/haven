# frozen_string_literal: true

# This migration is added to circumvent issue #623 and have special characters
# work properly

class ChangeCollationForTagNames < ActiveRecord::Migration[6.0]
  def up
    if ActsAsTaggableOn::Utils.using_mysql? && column_exists?(ActsAsTaggableOn.tags_table, :name)
      execute("ALTER TABLE #{ActsAsTaggableOn.tags_table} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
    end
  end
end
