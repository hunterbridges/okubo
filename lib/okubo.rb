require 'okubo/base'
require 'okubo/deck_methods'
require 'okubo/item_methods'
require 'okubo/models/deck'
require 'okubo/models/item'
require 'okubo/models/study_session'
require "okubo/version"

ActiveRecord::Base.send(:include, Okubo::Base)