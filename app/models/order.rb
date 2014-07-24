class Order < ActiveRecord::Base
   always_background :pack_order

  def pack_order
    puts "Order #{id} is being packed"
    update_attributes!(status: 'packing', packed_on: Time.now)
    sleep(10)
    update_attributes!(status: 'packed', packed_on: Time.now)
    puts "Order #{id} has been packed"
  end
end
