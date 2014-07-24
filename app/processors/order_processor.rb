class OrderProcessor < TorqueBox::Messaging::MessageProcessor

  def on_message(message)
    puts "Courrier picked up: #{message}"
    hash = JSON.parse(message)

    order = Order.find(hash['id'])
    order.update_attributes!(status: 'delivering', delivered_on: Time.now)

    sleep 20

    puts "Courrier delivered order #{order.id}"
    order.update_attributes!(status: 'delivered', delivered_on: Time.now)
  end

end