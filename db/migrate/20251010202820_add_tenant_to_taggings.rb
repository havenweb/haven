# frozen_string_literal: true

class AddTenantToTaggings < ActiveRecord::Migration[6.0]
  def self.up
    unless column_exists?(ActsAsTaggableOn.taggings_table, :tenant)
      add_column ActsAsTaggableOn.taggings_table, :tenant, :string, limit: 128
    end
    add_index ActsAsTaggableOn.taggings_table, :tenant unless index_exists?(ActsAsTaggableOn.taggings_table, :tenant)
  end

  def self.down
    remove_index ActsAsTaggableOn.taggings_table, :tenant
    remove_column ActsAsTaggableOn.taggings_table, :tenant
  end
end
