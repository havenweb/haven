# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_03_11_163322) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "author_id"
    t.bigint "post_id"
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "feed_entries", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "link"
    t.string "guid"
    t.datetime "published", precision: nil
    t.bigint "feed_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "sort_date", precision: nil
    t.string "audio"
    t.index ["feed_id"], name: "index_feed_entries_on_feed_id"
    t.index ["guid"], name: "index_feed_entries_on_guid"
    t.index ["published"], name: "index_feed_entries_on_published"
    t.index ["sort_date"], name: "index_feed_entries_on_sort_date"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_update", precision: nil
    t.integer "status", default: 0
    t.bigint "user_id"
    t.index ["user_id"], name: "index_feeds_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "indie_auth_requests", force: :cascade do |t|
    t.bigint "user_id"
    t.string "code"
    t.string "state"
    t.string "code_challenge"
    t.string "client_id"
    t.string "scope"
    t.integer "used", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_indie_auth_requests_on_code", unique: true
  end

  create_table "indie_auth_tokens", force: :cascade do |t|
    t.bigint "user_id"
    t.string "access_token"
    t.string "scope"
    t.string "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index indie_auth_tokens_on_access_token", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.string "reaction", default: "👍"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.bigint "post_id"
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "login_links", force: :cascade do |t|
    t.string "token"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_login_links_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "datetime", precision: nil
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "author_id"
    t.index ["author_id"], name: "index_posts_on_author_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "visibility"
    t.text "css"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "compiled_css"
    t.string "css_hash"
    t.boolean "byline", default: false
    t.boolean "comments", default: false
    t.string "font_hash"
    t.boolean "show_post_date", default: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.integer "admin"
    t.string "basic_auth_username", null: false
    t.string "basic_auth_password", null: false
    t.string "image_password", null: false
    t.index ["basic_auth_username"], name: "index_users_on_basic_auth_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "feed_entries", "feeds"
  add_foreign_key "feeds", "users"
  add_foreign_key "indie_auth_requests", "users"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "login_links", "users"
  add_foreign_key "posts", "users", column: "author_id"
end
