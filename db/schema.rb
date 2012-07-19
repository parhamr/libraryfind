# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 32) do

  create_table "_Cache", :id => false, :force => true do |t|
    t.string  "m_query"
    t.string  "m_id",    :limit => 50
    t.string  "m_set",   :limit => 150
    t.text    "file",    :limit => 2147483647
    t.text    "m_url",   :limit => 2147483647
    t.integer "m_use"
    t.integer "m_deep",                        :default => 0
    t.date    "m_date"
  end

  add_index "_Cache", ["m_id"], :name => "m_id"
  add_index "_Cache", ["m_query"], :name => "m_query"
  add_index "_Cache", ["m_set"], :name => "m_set"

  create_table "_Collection", :force => true do |t|
    t.string  "name"
    t.text    "alias",      :limit => 2147483647
    t.string  "type",       :limit => 100
    t.string  "host"
    t.text    "user",       :limit => 2147483647
    t.text    "pass",       :limit => 2147483647
    t.string  "schema"
    t.text    "definition", :limit => 2147483647
    t.integer "isword",                           :default => 0
    t.text    "url",        :limit => 2147483647
    t.string  "mat_type",                         :default => "Article"
    t.string  "virtual"
    t.text    "vendor_url", :limit => 2147483647
    t.string  "bib_attr"
  end

  add_index "_Collection", ["name"], :name => "name"
  add_index "_Collection", ["schema"], :name => "schema"
  add_index "_Collection", ["type"], :name => "type"

  create_table "_Control", :force => true do |t|
    t.string "identifier"
    t.text   "title",       :limit => 2147483647
    t.string "collection"
    t.text   "description", :limit => 2147483647
    t.text   "url",         :limit => 2147483647
  end

  add_index "_Control", ["identifier"], :name => "identifier"

  create_table "_History", :id => false, :force => true do |t|
    t.string  "username"
    t.text    "query"
    t.text    "url",      :limit => 2147483647
    t.integer "count"
    t.string  "m_id",     :limit => 50
    t.string  "m_set",    :limit => 150
    t.date    "accessed"
  end

  add_index "_History", ["accessed"], :name => "accessed"
  add_index "_History", ["m_id"], :name => "m_id"
  add_index "_History", ["m_set"], :name => "m_set"
  add_index "_History", ["query"], :name => "query"
  add_index "_History", ["username"], :name => "username"

  create_table "_Metadata", :force => true do |t|
    t.text "title",       :limit => 2147483647
    t.text "creator",     :limit => 2147483647
    t.text "subject",     :limit => 2147483647
    t.text "description", :limit => 2147483647
    t.text "publisher",   :limit => 2147483647
    t.text "contributor", :limit => 2147483647
    t.text "date",        :limit => 2147483647
    t.text "type",        :limit => 2147483647
    t.text "format",      :limit => 2147483647
    t.text "identifier",  :limit => 2147483647
    t.text "source",      :limit => 2147483647
    t.text "language",    :limit => 2147483647
    t.text "relation",    :limit => 2147483647
    t.text "coverage",    :limit => 2147483647
    t.text "rights",      :limit => 2147483647
    t.text "keyword",     :limit => 2147483647
  end

  add_index "_Metadata", ["contributor"], :name => "contributor"
  add_index "_Metadata", ["coverage"], :name => "coverage"
  add_index "_Metadata", ["creator"], :name => "creator"
  add_index "_Metadata", ["description"], :name => "description"
  add_index "_Metadata", ["keyword"], :name => "keyword"
  add_index "_Metadata", ["publisher"], :name => "publisher"
  add_index "_Metadata", ["subject"], :name => "subject"
  add_index "_Metadata", ["title"], :name => "title"

  create_table "_RSS", :id => false, :force => true do |t|
    t.text    "m_file",  :limit => 2147483647
    t.integer "m_use",                         :default => 0
    t.text    "m_query", :limit => 2147483647
  end

  create_table "_Users", :force => true do |t|
    t.string "username"
    t.text   "email"
    t.text   "dept",     :limit => 2147483647
  end

  add_index "_Users", ["username"], :name => "username"

  create_table "cached_records", :force => true do |t|
    t.integer  "search_id"
    t.text     "data",          :limit => 2147483647
    t.integer  "collection_id"
    t.datetime "created_at"
    t.integer  "max_recs",                            :default => 0
    t.integer  "status",                              :default => 0
    t.string   "search_time"
  end

  add_index "cached_records", ["search_id"], :name => "cached_records_search_id_index"

  create_table "cached_searches", :force => true do |t|
    t.string   "query_string"
    t.string   "query_type"
    t.string   "collection_set"
    t.datetime "created_at",       :default => '2006-10-25 11:10:36'
    t.boolean  "in_cache",         :default => false
    t.datetime "cache_updated_at", :default => '2006-10-25 11:10:36'
    t.integer  "max_recs",         :default => 0
  end

  add_index "cached_searches", ["cache_updated_at", "in_cache"], :name => "cached_searches_cache_updated_at_index"
  add_index "cached_searches", ["created_at"], :name => "cached_searches_created_at_index"
  add_index "cached_searches", ["query_string", "query_type", "collection_set"], :name => "cached_searches_query_string_index"

  create_table "collection_group_members", :force => true do |t|
    t.integer "collection_group_id"
    t.integer "collection_id"
    t.boolean "default_on",          :default => false
  end

  add_index "collection_group_members", ["collection_group_id"], :name => "index_collection_group_members_on_collection_group_id"
  add_index "collection_group_members", ["collection_id"], :name => "index_collection_group_members_on_collection_id"

  create_table "collection_groups", :force => true do |t|
    t.string  "name"
    t.string  "full_name"
    t.text    "description"
    t.boolean "enabled",     :default => false
  end

  create_table "collections", :force => true do |t|
    t.string  "name"
    t.text    "alt_name"
    t.string  "conn_type"
    t.string  "host"
    t.text    "user"
    t.text    "pass"
    t.string  "record_schema"
    t.text    "definition"
    t.integer "isword"
    t.text    "url"
    t.string  "mat_type",      :default => "Article"
    t.string  "virtual"
    t.text    "vendor_url"
    t.string  "bib_attr"
    t.integer "proxy",         :default => 1
    t.string  "harvested",     :default => ""
    t.integer "is_parent",     :default => 0
    t.integer "is_private",    :default => 0
  end

  create_table "controls", :force => true do |t|
    t.string  "oai_identifier"
    t.string  "title"
    t.integer "collection_id"
    t.string  "description"
    t.string  "url"
    t.string  "collection_name", :default => ""
  end

  add_index "controls", ["oai_identifier"], :name => "controls_oai_identifier_index"

  create_table "coverages", :force => true do |t|
    t.string  "journal_title"
    t.string  "issn"
    t.string  "eissn"
    t.string  "isbn"
    t.string  "start_date"
    t.string  "end_date"
    t.string  "provider"
    t.string  "url"
    t.integer "mod_date"
  end

  add_index "coverages", ["eissn"], :name => "coverages_eissn_index"
  add_index "coverages", ["end_date"], :name => "coverages_end_date_index"
  add_index "coverages", ["isbn"], :name => "coverages_isbn_index"
  add_index "coverages", ["issn"], :name => "coverages_issn_index"
  add_index "coverages", ["journal_title"], :name => "coverages_journal_title_index"
  add_index "coverages", ["mod_date"], :name => "coverages_mod_date_index"
  add_index "coverages", ["provider"], :name => "coverages_provider_index"
  add_index "coverages", ["start_date"], :name => "coverages_start_date_index"

  create_table "hits", :force => true do |t|
    t.integer "session_id"
    t.integer "search_id"
    t.integer "result_count"
    t.string  "action_type"
    t.text    "data"
  end

  add_index "hits", ["action_type"], :name => "hits_action_type_index"
  add_index "hits", ["search_id"], :name => "hits_search_id_index"
  add_index "hits", ["session_id"], :name => "hits_session_id_index"

  create_table "job_queues", :force => true do |t|
    t.integer "records_id",    :default => -1
    t.integer "status",        :default => 0
    t.integer "hits",          :default => 0
    t.string  "error"
    t.integer "thread_id",     :default => 0
    t.string  "database_name", :default => ""
  end

  create_table "metadatas", :force => true do |t|
    t.integer "collection_id"
    t.integer "controls_id"
    t.text    "dc_title"
    t.text    "dc_creator"
    t.text    "dc_subject"
    t.text    "dc_description"
    t.text    "dc_publisher"
    t.text    "dc_contributor"
    t.text    "dc_date"
    t.text    "dc_type"
    t.text    "dc_format"
    t.text    "dc_identifier"
    t.text    "dc_source"
    t.text    "dc_relation"
    t.text    "dc_coverage"
    t.text    "dc_rights"
    t.text    "osu_volume"
    t.text    "osu_issue"
    t.text    "osu_linking"
    t.string  "osu_openurl"
    t.string  "osu_thumbnail",  :default => ""
    t.string  "osu_callnum",    :default => ""
  end

  add_index "metadatas", ["collection_id"], :name => "metadatas_collection_id_index"
  add_index "metadatas", ["controls_id"], :name => "metadatas_controls_id_index"

  create_table "providers", :force => true do |t|
    t.string  "provider_name"
    t.string  "title"
    t.string  "url"
    t.string  "article_type"
    t.string  "proxy"
    t.integer "can_resolve",   :default => 1
  end

  add_index "providers", ["provider_name"], :name => "providers_provider_name_index"
  add_index "providers", ["title"], :name => "providers_title_index"

  create_table "records", :force => true do |t|
    t.text   "title",                         :null => false
    t.text   "full_text",                     :null => false
    t.string "mat_type",      :default => "", :null => false
    t.text   "abstract",                      :null => false
    t.date   "pub_date",                      :null => false
    t.string "journal_url",   :default => "", :null => false
    t.string "journal_title", :default => "", :null => false
    t.string "db_name",       :default => "", :null => false
    t.string "db_url",        :default => "", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "session_id_idx"

  create_table "site_configs", :force => true do |t|
    t.string   "field"
    t.string   "value"
    t.string   "previous_value"
    t.datetime "updated_at",     :default => '2006-10-25 11:10:38'
  end

  add_index "site_configs", ["field"], :name => "site_configs_field_index"

  create_table "users", :force => true do |t|
    t.string  "name",            :limit => 25
    t.string  "full_name",       :limit => 100
    t.string  "email"
    t.string  "hashed_password"
    t.string  "salt"
    t.boolean "administrator",                  :default => false
  end

end
