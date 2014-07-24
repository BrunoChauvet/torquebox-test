class OrderInventory

  include TorqueBox::Injectors

  def run
    packed_orders = Order.where(status: 'packed')

    if packed_orders.empty?
      puts "No order to be delivered"
    else
      puts "#{packed_orders.size} Orders ready to be delivered"
      order_delivery = fetch( 'service:order_delivery' )
      packed_orders.each do |packed_order|
        order_delivery.deliver(packed_order)
      end
    end
    
  end

end