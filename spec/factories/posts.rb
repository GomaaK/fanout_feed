FactoryGirl.define do
  factory :post do
    lat { Faker::Address.longitude }
    lng { Faker::Address.latitude }
    user
  end

end
