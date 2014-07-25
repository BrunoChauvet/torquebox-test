torquebox-test
==============

## Demonstration of TorqueBox features: Background processes, Queues and Cron Jobs

TorqueBox has to be run using JRuby. It has been tested with TorqueBox 3.1.1 and JRuby-1.7.13
More information here: http://torquebox.org/builds/LATEST/getting-started/first-steps.html

## Run the test application
```shell
$ bundle
$ rake db:migrate
$ torquebox deploy
$ torquebox run
```

This will fire up a JBossAS instance running on port 8080. You can verify the logs in the file
`JRUBY_PATH/jruby-1.7.13@global/gems/torquebox-server-3.1.1-java/jboss/standalone/log/server.log`
You should then be able to access [http://localhost:8080/orders](http://localhost:8080/orders)

----------------------------------------------------------------
![alt text](http://i60.tinypic.com/15p252s.png "TorqueBox Test")
----------------------------------------------------------------

### What is does

1. A new Order is created from the UI
2. A background job starts packing the order
3. A cron job runs periodically to pass the packed orders to an orders delivery queue
4. A courrier grabs an order to be delivered from the queue and goes off

### How it works
#### Create a new Order
*app/controllers/orders_controller.rb*
```ruby
def create
  ...
  @order = Order.new(order_params.merge({placed_on: Time.now}))
  @order.save
  @order.pack_order
  ...
end
```

*app/models/order.rb*
```ruby
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
```

Where the instruction `always_background :pack_order` sets `pack_order` to be run in the background. So the Order creation from the UI does not wait for this method to return.

#### Process packed Orders
*app/services/order_delivery.rb*
```ruby
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
```

*app/jobs/order_inventory.rb*
```ruby
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
```

The configuration of the Jobs, Processors, Services and Queues resides in the file `config/torquebox.yml`
*config/torquebox.yml*
```
jobs:
  order_inventory:
    job: OrderInventory
    cron: "*/10 * * * * ?"

queues:
  /queue/deliver_order:
    durable: false

services:
  order_delivery:
    service: OrderDelivery
    config:
      queue_name: "/queue/deliver_order"
```

Note that `OrderDelivery` is created as a signleton instance and can be injected in our `OrderInventory` using
```ruby
  TorqueBox::Injectors
  order_delivery = fetch( 'service:order_delivery' )
```

#### Read messages from the Queue
*app/jobs/order_inventory.rb*
```ruby
class OrderProcessor < TorqueBox::Messaging::MessageProcessor
  def on_message(message)
    puts "Courrier picked up: #{message}"

    order = Order.find(JSON.parse(message)['id'])
    order.update_attributes!(status: 'delivering', delivered_on: Time.now)
    sleep 20
    
    puts "Courrier delivered order #{order.id}"
    order.update_attributes!(status: 'delivered', delivered_on: Time.now)
  end
end
```
*config/torquebox.yml*
```
messaging:
  /queue/deliver_order: OrderProcessor
```

When creating a new Order, you should find the following in the logs:
```
09:33:37,302 INFO  Order 1 is being packed
09:33:47,885 INFO  Order 1 has been packed
09:33:50,026 INFO  1 Orders ready to be delivered
09:33:50,046 INFO  Assigning order 1 to courrier
09:33:50,074 INFO  Courrier picked up: {"id":1,"placed_on":"2000-01-01T23:33:33.000Z","packed_on":"2000-01-01T23:33:47.000Z","delivered_on":null,"description":"Order 1","status":"packed","created_at":"2014-07-24T23:33:33.838Z","updated_at":"2014-07-24T23:33:47.864Z"}
09:34:13,808 INFO  Courrier delivered order 1
```
