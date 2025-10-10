# frozen_string_literal: true

class ActsAsTaggableOnMigration < ActiveRecord::Migration[6.0]
  def self.up
    unless table_exists?(ActsAsTaggableOn.tags_table)
      create_table ActsAsTaggableOn.tags_table do |t|
        t.string :name
        t.timestamps
      end
    end

    unless table_exists?(ActsAsTaggableOn.taggings_table)
      create_table ActsAsTaggableOn.taggings_table do |t|
        t.references :tag, foreign_key: { to_table: ActsAsTaggableOn.tags_table }
        t.references :taggable, polymorphic: true
        t.references :tagger, polymorphic: true
        t.string :context, limit: 128
        t.datetime :created_at
      end

      add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
                name: 'taggings_taggable_context_idx'
    end
  end

  def self.down
    drop_table ActsAsTaggableOn.taggings_table if table_exists?(ActsAsTaggableOn.taggings_table)
    drop_table ActsAsTaggableOn.tags_table if table_exists?(ActsAsTaggableOn.tags_table)
  end
end