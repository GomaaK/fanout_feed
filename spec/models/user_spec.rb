require 'rails_helper'

describe User, type: :model do

  before  do 
    User.destroy_all
  end

  describe 'follow!' do

    let(:user) { FactoryGirl.create(:user) }

    let(:other_user) { FactoryGirl.create(:user) }

    it 'links them together' do
      user.follow! other_user
      expect(user.followed.first.to_i).to  eq(other_user.id)
      expect(other_user.followers.first.to_i).to  eq(user.id)
    end

  end

  describe 'unfollow!' do

    let(:user) { FactoryGirl.create(:user) }

    let(:other_user) { FactoryGirl.create(:user) }

    it 'breaks the link them together' do
      user.unfollow! other_user
      expect(user.followed.first.to_i).to  eq(other_user.id)
      expect(other_user.followers.first.to_i).to  eq(user.id)
    end

  end

end