# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Okubo::Base do
  before(:each) do
    @word = Word.create!(:kanji => "日本語", :kana => "にほんご", :translation => "Japanese language")
    @user = User.create!(:name => "Robert")
  end

  context "Mixin" do
    describe "#has_deck" do
      it "should add a decks method with name" do
        @user.respond_to?(:words).should be_true
      end
    end
  end
end