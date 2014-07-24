class OrderDelivery

  def initialize(options)
    @queue = TorqueBox::Messaging::Queue.new(options['queue_name'])
  end

  def deliver(order)
    puts "Assigning order #{order.id} to courrier"
    @queue.publish(order.to_json)
    order.update_attributes!(status: 'loading', delivered_on: Time.now)
  end
end